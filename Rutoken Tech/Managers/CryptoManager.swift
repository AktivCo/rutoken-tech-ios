//
//  CryptoManager.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//

import Combine
import Foundation


protocol CryptoManagerProtocol {
    func getTokenInfo(for type: ConnectionType) async throws -> TokenInfo
}

enum CryptoManagerError: Error, Equatable {
    case tokenNotFound
    case unknown
    case connectionLost
    case nfcStopped
    case incorrectPin(UInt)
}

class CryptoManager: CryptoManagerProtocol {
    private let pkcs11Helper: Pkcs11HelperProtocol
    private let pcscHelper: PcscHelperProtocol
    private var cancellable = [UUID: AnyCancellable]()
    @Atomic var tokens: [TokenProtocol] = []

    init(pkcs11Helper: Pkcs11HelperProtocol, pcscHelper: PcscHelperProtocol) {
        self.pkcs11Helper = pkcs11Helper
        self.pcscHelper = pcscHelper

        pkcs11Helper.tokens
            .assign(to: \.tokens, on: self)
            .store(in: &cancellable, for: UUID())
    }

    func getTokenInfo(for type: ConnectionType) async throws -> TokenInfo {
        defer {
            if type == .nfc {
                try? pcscHelper.stopNfc()
            }
        }
        do {
            if type == .nfc {
                try pcscHelper.startNfc()
            }
            let token = try await waitForToken(with: type)
            try token.login(with: "12345678")

            let keyPairId = "some random key pair id"
            try token.generateKeyPair(with: keyPairId)
            try token.deleteKeyPair(with: keyPairId)

            return TokenInfo(label: token.label, serial: token.serial, model: token.model,
                             connectionType: token.connectionType, type: token.type)
        } catch Pkcs11Error.connectionLost {
            throw CryptoManagerError.connectionLost
        } catch Pkcs11Error.tokenNotFound {
            throw CryptoManagerError.tokenNotFound
        } catch NfcError.cancelledByUser, NfcError.timeout {
            throw CryptoManagerError.nfcStopped
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
                    .compactMap { $0.first(where: { $0.connectionType == .nfc }) }
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
                guard let usbToken = tokens.first(where: { $0.connectionType == .usb }) else {
                    continuation.resume(throwing: CryptoManagerError.tokenNotFound)
                    return
                }
                continuation.resume(returning: usbToken)
            }
        }
    }
}
