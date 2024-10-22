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
    func generateKeyPair(with id: String) async throws
    func createCert(for id: String, with info: CsrModel) async throws
}

enum CryptoManagerError: Error, Equatable {
    case tokenNotFound
    case unknown
    case connectionLost
    case nfcStopped
    case incorrectPin(UInt)
    case wrongToken
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

    func generateKeyPair(with id: String) async throws {
        guard let token = connectedToken else {
            throw CryptoManagerError.tokenNotFound
        }
        return try token.generateKeyPair(with: id)
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

    func createCert(for id: String, with info: CsrModel) async throws {
        guard let token = connectedToken else {
            throw CryptoManagerError.tokenNotFound
        }
        let wrappedPrivateKey = try token.getWrappedKey(with: id)
        let csr = try openSslHelper.createCsr(with: wrappedPrivateKey, for: info)

        guard let caKey = fileHelper.getContent(of: .caKey) else {
            throw CryptoManagerError.unknown
        }
        guard let caCert = fileHelper.getContent(of: .caCert) else {
            throw CryptoManagerError.unknown
        }
        let cert = try openSslHelper.createCert(for: csr, with: caKey, and: caCert)
        try token.importCert(cert, for: id)
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
