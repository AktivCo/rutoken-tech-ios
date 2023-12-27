//
//  OnPerformGenKeyPair.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 25.12.2023.
//

import Foundation

import TinyAsyncRedux


class OnPerformGenKeyPair: Middleware {
    private let cryptoManager: CryptoManagerProtocol

    init(cryptoManager: CryptoManagerProtocol) {
        self.cryptoManager = cryptoManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .generateKeyPair(connectionType, serial, pin, id) = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            Task {
                do {
                    defer {
                        continuation.yield(.finishGenerateKeyPair)
                        continuation.yield(.hideSheet)
                        continuation.finish()
                    }
                    try await cryptoManager.withToken(connectionType: connectionType,
                                                      serial: serial,
                                                      pin: pin) {
                        try await cryptoManager.generateKeyPair(with: id)
                    }

                    continuation.yield(.showAlert(.keyGenerated))
                } catch CryptoManagerError.connectionLost {
                    continuation.yield(.showAlert(.connectionLost))
                } catch CryptoManagerError.wrongToken {
                    continuation.yield(.showAlert(.wrongToken))
                } catch {
                    continuation.yield(.showAlert(.unknownError))
                }
            }
        }
    }
}
