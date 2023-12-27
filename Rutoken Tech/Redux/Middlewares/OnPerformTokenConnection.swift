//
//  OnPerformTokenConnection.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2023-12-01.
//

import Foundation

import RtUiComponents
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

        let tokenInterface: ConnectionType = tokenType == .nfc ? .nfc : .usb
        return AsyncStream<AppAction> { continuation in
            Task {
                do {
                    try await self.cryptoManager.withToken(connectionType: tokenInterface,
                                                           serial: nil, pin: nil) {
                        let info = try await self.cryptoManager.getTokenInfo()
                        continuation.yield(.tokenSelected(info, pin))
                    }
                    continuation.yield(.hideSheet)
                } catch CryptoManagerError.incorrectPin(let attemptsLeft) {
                    continuation.yield(.showPinInputError("Неверный PIN-код. Осталось попыток: \(attemptsLeft)"))
                } catch CryptoManagerError.nfcStopped {
                } catch let error as CryptoManagerError {
                    continuation.yield(.showAlert(AppAlert(from: error)))
                }

                continuation.finish()
            }
        }
    }
}
