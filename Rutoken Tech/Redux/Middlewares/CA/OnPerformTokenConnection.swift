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
                if connectionType == .nfc {
                    continuation.yield(.lockNfc)
                }
                defer {
                    if connectionType == .nfc {
                        continuation.yield(.willUnlockNfc)
                    }
                    continuation.finish()
                }
                do {
                    try await self.cryptoManager.withToken(connectionType: connectionType,
                                                           serial: nil, pin: pin) {
                        let info = try await self.cryptoManager.getTokenInfo()
                        continuation.yield(.tokenSelected(info, pin))
                        let keys = try await self.cryptoManager.enumerateKeys()
                        continuation.yield(.updateKeys(keys))
                    }
                    continuation.yield(.hideSheet)
                } catch CryptoManagerError.incorrectPin(let attemptsLeft) {
                    continuation.yield(.showPinInputError("Неверный PIN-код. Осталось попыток: \(attemptsLeft)"))
                } catch CryptoManagerError.nfcStopped {
                } catch let error as CryptoManagerError {
                    continuation.yield(.showAlert(AppAlert(from: error)))
                }
            }
        }
    }
}
