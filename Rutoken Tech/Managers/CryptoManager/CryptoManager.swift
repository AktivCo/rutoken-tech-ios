//
//  CryptoManager.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//

import Combine
import Foundation
import UIKit


protocol CryptoManagerProtocol {
    func withToken(connectionType: ConnectionType,
                   serial: String?,
                   pin: String?,
                   callback: () async throws -> Void) async throws
    func getTokenInfo() async throws -> TokenInfo
    func enumerateKeys() async throws -> [KeyModel]
    func enumerateCerts() async throws -> [CertMetaData]
    func generateKeyPair(with id: String) async throws
    func createCert(for id: String, with info: CsrModel) async throws
    func signDocument(_ document: Data, certId: String) throws -> String
    func signDocument(_ document: Data, keyFile: RtFile, certFile: RtFile) throws -> String
    func deleteCert(with id: String) async throws
    func verifyCms(signedCms: Data, document: Data) async throws
    func encryptDocument(_ document: Data, certId: String) throws -> Data
    func encryptDocument(_ document: Data, certFile: RtFile) throws -> Data
    func encryptDocument(_ document: Data, certData: Data) throws -> Data
    func decryptCms(encryptedData: Data, with id: String) throws -> Data
    func startMonitoring() throws
    var tokenState: AnyPublisher<TokenInteractionState, Never> { get }
}

enum CryptoManagerError: Error, Equatable {
    case tokenNotFound
    case unknown
    case connectionLost
    case nfcStopped
    case incorrectPin(UInt)
    case wrongToken
    case noSuitCert
    case failedChain
    case invalidSignature
}

enum RtFile: String {
    case caKey = "ca.key"
    case caCert = "ca.pem"
    case rootCaKey = "rootCa.key"
    case rootCaCert = "rootCa.pem"
    case bankKey = "bank.key"
    case bankCert = "bank.pem"

    static var subdir: String {
        "Credentials"
    }
}


class CryptoManager: CryptoManagerProtocol {
    var tokenState: AnyPublisher<TokenInteractionState, Never> {
        tokenStatePublisher.eraseToAnyPublisher()
    }

    private let pkcs11Helper: Pkcs11HelperProtocol
    private let pcscHelper: PcscHelperProtocol
    private let openSslHelper: OpenSslHelperProtocol
    private let fileHelper: FileHelperProtocol
    private let fileSource: FileSourceProtocol
    private let deviceInfo: DeviceInfoHelperProtocol

    private var cancellable = [UUID: AnyCancellable]()
    @Atomic var tokens: [Pkcs11TokenProtocol] = []
    private var connectedToken: Pkcs11TokenProtocol?

    private var tokenStatePublisher = PassthroughSubject<TokenInteractionState, Never>()

    init(pkcs11Helper: Pkcs11HelperProtocol,
         pcscHelper: PcscHelperProtocol,
         openSslHelper: OpenSslHelperProtocol,
         fileHelper: FileHelperProtocol,
         fileSource: FileSourceProtocol,
         deviceInfo: DeviceInfoHelperProtocol = DeviceInfoHelper()) {
        self.pkcs11Helper = pkcs11Helper
        self.pcscHelper = pcscHelper
        self.openSslHelper = openSslHelper
        self.fileHelper = fileHelper
        self.fileSource = fileSource
        self.deviceInfo = deviceInfo

        pkcs11Helper.tokens
            .assign(to: \.tokens, on: self)
            .store(in: &cancellable, for: UUID())
    }

    func startMonitoring() throws {
        do {
            try pkcs11Helper.startMonitoring()
        } catch {
            throw CryptoManagerError.unknown
        }
    }

    func getTokenInfo() async throws -> TokenInfo {
        guard let token = connectedToken else {
            throw CryptoManagerError.tokenNotFound
        }

        let type: TokenType
        let connectionType: ConnectionType

        switch token.currentInterface {
        case .nfc:
            type = token.supportedInterfaces.contains(.usb) ? .dual : .sc
            connectionType = .nfc
        case .sc:
            type = .sc
            connectionType = .usb
        case .usb:
            type = token.supportedInterfaces.contains(.nfc) ? .dual : .usb
            connectionType = .usb
        }

        return TokenInfo(label: token.label, serial: token.serial, model: token.model,
                         connectionType: connectionType, type: type)
    }

    func enumerateKeys() async throws -> [KeyModel] {
        guard let token = connectedToken else {
            throw CryptoManagerError.tokenNotFound
        }

        return try token.enumerateKeys(by: .gostR3410_2012_256).compactMap {
            guard let ckaId = try String(data: $0.privateKey.getValue(forAttr: .id), encoding: .utf8) else {
                return nil
            }
            return KeyModel(ckaId: ckaId, type: $0.algorithm)
        }
    }

    func enumerateCerts() async throws -> [CertMetaData] {
        guard let token = connectedToken else {
            throw CryptoManagerError.tokenNotFound
        }

        return try token.enumerateCerts().compactMap { (cert: Pkcs11ObjectProtocol) -> CertMetaData? in
            let certData = try cert.getValue(forAttr: .value)
            guard let keyId = try String(data: cert.getValue(forAttr: .id), encoding: .utf8) else {
                return nil
            }

            return CertMetaData(keyId: keyId, tokenSerial: token.serial, from: certData)
        }
    }

    func generateKeyPair(with id: String) async throws {
        guard let token = connectedToken else {
            throw CryptoManagerError.tokenNotFound
        }
        return try token.generateKeyPair(with: id)
    }

    func createCert(for id: String, with model: CsrModel) async throws {
        guard let token = connectedToken else {
            throw CryptoManagerError.tokenNotFound
        }

        guard let caKeyUrl = fileSource.getUrl(for: RtFile.caKey.rawValue, in: .credentials),
              let caCertUrl = fileSource.getUrl(for: RtFile.caCert.rawValue, in: .credentials) else {
            throw CryptoManagerError.unknown
        }

        let caKeyData = try fileHelper.readFile(from: caKeyUrl)
        let caCertData = try fileHelper.readFile(from: caCertUrl)

        let keyPair = try token.enumerateKey(by: id)
        let startDateData = try keyPair.privateKey.getValue(forAttr: .startDate)
        let endDateData = try keyPair.privateKey.getValue(forAttr: .endDate)
        let info = CertInfo(startDate: startDateData.getDate(with: "YYYYMMdd"),
                            endDate: endDateData.getDate(with: "YYYYMMdd"))

        let wrappedKey = try token.getWrappedKey(with: id)
        defer { wrappedKey.release() }

        let csr = try openSslHelper.createCsr(with: wrappedKey, for: model, with: info)
        let cert = try openSslHelper.createCert(for: csr, with: caKeyData, cert: caCertData)
        try token.importCert(cert, for: id)
    }

    func deleteCert(with id: String) async throws {
        guard let token = connectedToken else {
            throw CryptoManagerError.tokenNotFound
        }

        try token.deleteCert(with: id)
    }

    func signDocument(_ document: Data, certId: String) throws -> String {
        guard let token = connectedToken else {
            throw CryptoManagerError.tokenNotFound
        }
        let key = try token.getWrappedKey(with: certId)
        defer { key.release() }

        guard let userCertData = try token.enumerateCerts(by: certId).first?.getValue(forAttr: .value) else {
            throw CryptoManagerError.noSuitCert
        }

        guard let caCertUrl = fileSource.getUrl(for: RtFile.caCert.rawValue, in: .credentials) else {
            throw CryptoManagerError.unknown
        }
        let caCertData = try fileHelper.readFile(from: caCertUrl)

        return try openSslHelper.signDocument(document, wrappedKey: key, cert: userCertData, certChain: [caCertData])
    }

    func signDocument(_ document: Data, keyFile: RtFile, certFile: RtFile) throws -> String {
        guard let keyUrl = fileSource.getUrl(for: keyFile.rawValue, in: .credentials),
              let certUrl = fileSource.getUrl(for: certFile.rawValue, in: .credentials),
              let caCertUrl = fileSource.getUrl(for: RtFile.caCert.rawValue, in: .credentials) else {
            throw CryptoManagerError.unknown
        }
        let keyData = try fileHelper.readFile(from: keyUrl)
        let certData = try fileHelper.readFile(from: certUrl)
        let caCertData = try fileHelper.readFile(from: caCertUrl)

        return try openSslHelper.signDocument(document, key: keyData, cert: certData, certChain: [caCertData])
    }

    func verifyCms(signedCms: Data, document: Data) async throws {
        guard let cms = String(data: signedCms, encoding: .utf8),
              let rootCaCertUrl = fileSource.getUrl(for: RtFile.rootCaCert.rawValue, in: .credentials) else {
            throw CryptoManagerError.unknown
        }

        do {
            let rootCaCertData = try fileHelper.readFile(from: rootCaCertUrl)

            switch try openSslHelper.verifyCms(signedCms: cms, for: document, trustedRoots: [rootCaCertData]) {
            case .success:
                return
            case .failedChain:
                throw CryptoManagerError.failedChain
            case .invalidSignature:
                throw CryptoManagerError.invalidSignature
            }
        } catch let error as CryptoManagerError {
            throw error
        } catch {
            throw CryptoManagerError.unknown
        }
    }

    func encryptDocument(_ document: Data, certId: String) throws -> Data {
        guard let token = connectedToken else {
            throw CryptoManagerError.tokenNotFound
        }
        guard let certData = try token.enumerateCerts(by: certId).first?.getValue(forAttr: .value) else {
            throw CryptoManagerError.noSuitCert
        }
        return try openSslHelper.encryptDocument(for: document, with: certData)
    }

    func encryptDocument(_ document: Data, certFile: RtFile) throws -> Data {
        guard let certUrl = fileSource.getUrl(for: certFile.rawValue, in: .credentials) else {
            throw CryptoManagerError.unknown
        }
        let certData = try fileHelper.readFile(from: certUrl)
        return try openSslHelper.encryptDocument(for: document, with: certData)
    }

    func encryptDocument(_ document: Data, certData: Data) throws -> Data {
        return try openSslHelper.encryptDocument(for: document, with: certData)
    }

    func decryptCms(encryptedData: Data, with id: String) throws -> Data {
        guard let token = connectedToken else {
            throw CryptoManagerError.tokenNotFound
        }
        let key = try token.getWrappedKey(with: id)
        defer { key.release() }

        return try openSslHelper.decryptCms(content: encryptedData, wrappedKey: key)
    }

    func withToken(connectionType: ConnectionType,
                   serial: String?,
                   pin: String?,
                   callback: () async throws -> Void) async throws {
        tokenStatePublisher.send(.inProgress(isVcr: connectionType == .nfc && !deviceInfo.isPhone))

        defer {
            if connectionType == .nfc {
                try? pcscHelper.stopNfc()
                Task {
                    do {
                        for try await cd in pcscHelper.getNfcCooldown() {
                            tokenStatePublisher.send(cd > 0 ? .cooldown(cd) : .ready)
                        }
                    } catch {
                        tokenStatePublisher.send(.ready)
                    }
                }
            } else {
                tokenStatePublisher.send(.ready)
            }
            connectedToken = nil
        }
        do {
            if connectionType == .nfc {
                try pcscHelper.startNfc()
            }

            connectedToken = try await waitForToken(with: connectionType)

            if let serial {
                guard connectedToken?.serial == serial else {
                    throw CryptoManagerError.wrongToken
                }
            }

            if let pin {
                try connectedToken?.login(with: pin)
            }

            defer {
                if pin != nil { connectedToken?.logout() }
            }

            try await callback()
        } catch NfcError.cancelledByUser, NfcError.timeout {
            throw CryptoManagerError.nfcStopped
        } catch Pkcs11Error.incorrectPin {
            throw CryptoManagerError.incorrectPin((try? connectedToken?.getPinAttempts()) ?? 0)
        } catch Pkcs11Error.internalError {
            guard let slot = connectedToken?.slot else {
                throw CryptoManagerError.connectionLost
            }
            throw pkcs11Helper.isPresent(slot) ? CryptoManagerError.unknown : CryptoManagerError.connectionLost
        } catch let error as CryptoManagerError {
            throw error
        } catch {
            throw CryptoManagerError.unknown
        }
    }

    private func waitForToken(with type: ConnectionType) async throws -> Pkcs11TokenProtocol {
        try await withCheckedThrowingContinuation { continuation in
            switch type {
            case .nfc:
                let nfcTokenFind = pkcs11Helper.tokens
                    .compactMap { $0.first(where: { $0.currentInterface == .nfc }) }
                    .map { Optional($0) }
                    .eraseToAnyPublisher()

                let uuid = UUID()
                Publishers.CombineLatest(pcscHelper.nfcExchangeIsStopped().prepend(()), nfcTokenFind.prepend(nil))
                    .dropFirst()
                    .sink { result in
                        guard let nfcToken = result.1 else {
                            self.cancellable.removeValue(forKey: uuid)
                            continuation.resume(throwing: CryptoManagerError.tokenNotFound)
                            return
                        }
                        self.cancellable.removeValue(forKey: uuid)
                        continuation.resume(returning: nfcToken)
                    }
                    .store(in: &cancellable, for: uuid)
            case .usb:
                guard let usbToken = tokens.first(where: { $0.currentInterface == .usb }) else {
                    continuation.resume(throwing: CryptoManagerError.tokenNotFound)
                    return
                }
                continuation.resume(returning: usbToken)
            }
        }
    }
}
