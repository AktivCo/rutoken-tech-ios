//
//  OnPerformTokenConnection.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2023-12-01.
//

import TinyAsyncRedux


class OnPerformTokenConnection: Middleware {
    private let cryptoManager: CryptoManagerProtocol

    init(cryptoManager: CryptoManagerProtocol) {
        self.cryptoManager = cryptoManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .selectToken(tokenType, pin) = action else {
            return nil
        }

        let connectionType: ConnectionType = tokenType == .nfc ? .nfc : .usb
        return AsyncStream<AppAction> { continuation in
            Task {
                defer {
                    continuation.finish()
                }

                do {
                    try await self.cryptoManager.withToken(connectionType: connectionType,
                                                           serial: nil, pin: pin) {
                        let info = try await self.cryptoManager.getTokenInfo()
                        continuation.yield(.tokenSelected(info, pin))
                        let keys = try await self.cryptoManager.enumerateKeys()
                        let certs = try await self.cryptoManager.enumerateCerts()
                        continuation.yield(.updateKeys(keys))
                        continuation.yield(.cacheCaCerts(certs))
                    }
                    continuation.yield(.hideSheet)
                } catch {
                    continuation.yield(.handleError(error))
                }
            }
        }
    }
}
