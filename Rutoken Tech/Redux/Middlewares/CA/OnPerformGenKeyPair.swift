//
//  OnPerformGenKeyPair.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 25.12.2023.
//

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
                defer {
                    continuation.finish()
                }
                do {
                    try await cryptoManager.withToken(connectionType: connectionType,
                                                      serial: serial,
                                                      pin: pin) {
                        try await cryptoManager.generateKeyPair(with: id)
                        let keys = try await self.cryptoManager.enumerateKeys()
                        continuation.yield(.updateKeys(keys))
                    }

                    continuation.yield(.showAlert(.keyGenerated))
                    continuation.yield(.hideSheet)
                } catch {
                    switch error {
                    case CryptoManagerError.incorrectPin:
                        continuation.yield(.handleError(nil, [AppAction.hideSheet,
                                                         .logout,
                                                         .showAlert(.pinHasChanged)]))
                    default:
                        continuation.yield(.handleError(error))
                    }
                }
            }
        }
    }
}
