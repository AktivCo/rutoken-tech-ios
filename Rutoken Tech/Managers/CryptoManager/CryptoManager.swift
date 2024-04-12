//
//  CryptoManager.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//

import Combine
import Foundation


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
    func signDocument(document: Data, with id: String) throws -> String
    func startMonitoring() throws
}

enum CryptoManagerError: Error, Equatable {
    case tokenNotFound
    case unknown
    case connectionLost
    case nfcStopped
    case incorrectPin(UInt)
    case wrongToken
    case noSuitCert
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
    private let pkcs11Helper: Pkcs11HelperProtocol
    private let pcscHelper: PcscHelperProtocol
    private let openSslHelper: OpenSslHelperProtocol
    private let fileHelper: FileHelperProtocol

    private var cancellable = [UUID: AnyCancellable]()
    @Atomic var tokens: [TokenProtocol] = []
    private var connectedToken: TokenProtocol?

    init(pkcs11Helper: Pkcs11HelperProtocol,
         pcscHelper: PcscHelperProtocol,
         openSslHelper: OpenSslHelperProtocol,
         fileHelper: FileHelperProtocol) {
        self.pkcs11Helper = pkcs11Helper
        self.pcscHelper = pcscHelper
        self.openSslHelper = openSslHelper
        self.fileHelper = fileHelper

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

        return try token.enumerateKeys(by: nil, with: .gostR3410_2012_256).compactMap {
            guard let ckaId = $0.privateKey.id else {
                return nil
            }
            return KeyModel(ckaId: ckaId, type: $0.algorithm)
        }
    }

    func enumerateCerts() async throws -> [CertMetaData] {
        guard let token = connectedToken else {
            throw CryptoManagerError.tokenNotFound
        }

        return try token.enumerateCerts(by: nil).compactMap { (cert: Pkcs11ObjectProtocol) -> CertMetaData? in
            guard let certData = cert.body,
                  let keyId = cert.id else {
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

    func createCert(for id: String, with info: CsrModel) async throws {
        guard let token = connectedToken else {
            throw CryptoManagerError.tokenNotFound
        }
        let wrappedPrivateKey = try token.getWrappedKey(with: id)
        let csr = try openSslHelper.createCsr(with: wrappedPrivateKey, for: info)

        guard let caKeyUrl = Bundle.getUrl(for: RtFile.caKey.rawValue, in: RtFile.subdir),
              let caCertUrl = Bundle.getUrl(for: RtFile.caCert.rawValue, in: RtFile.subdir),
              let caKeyData = try? fileHelper.readFile(from: caKeyUrl),
              let caCertData = try? fileHelper.readFile(from: caCertUrl) else {
            throw CryptoManagerError.unknown
        }

        let cert = try openSslHelper.createCert(for: csr, with: caKeyData, cert: caCertData)
        try token.importCert(cert, for: id)
    }

    func signDocument(document: Data, with id: String) throws -> String {
        guard let token = connectedToken else {
            throw CryptoManagerError.tokenNotFound
        }
        let key = try token.getWrappedKey(with: id)
        guard let certData = try token.enumerateCerts(by: id).first?.body else {
            throw CryptoManagerError.noSuitCert
        }
        return try openSslHelper.signCms(for: document, wrappedKey: key, cert: certData)
    }

    func withToken(connectionType: ConnectionType,
                   serial: String?,
                   pin: String?,
                   callback: () async throws -> Void) async throws {
        defer {
            if connectionType == .nfc {
                try? pcscHelper.stopNfc()
            }
        }
        do {
            if connectionType == .nfc {
                try pcscHelper.startNfc()
            }

            connectedToken = try await waitForToken(with: connectionType)
            defer { connectedToken = nil }

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
        } catch Pkcs11Error.connectionLost {
            throw CryptoManagerError.connectionLost
        } catch Pkcs11Error.tokenNotFound {
            throw CryptoManagerError.tokenNotFound
        } catch NfcError.cancelledByUser, NfcError.timeout {
            throw CryptoManagerError.nfcStopped
        } catch TokenError.tokenDisconnected {
            throw CryptoManagerError.connectionLost
        } catch TokenError.incorrectPin(let attemptsLeft) {
            throw CryptoManagerError.incorrectPin(attemptsLeft)
        } catch TokenError.lockedPin {
            throw CryptoManagerError.incorrectPin(0)
        } catch let error as CryptoManagerError {
            throw error
        } catch {
            throw CryptoManagerError.unknown
        }
    }

    private func waitForToken(with type: ConnectionType) async throws -> TokenProtocol {
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
