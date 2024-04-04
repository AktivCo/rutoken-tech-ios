//
//  OnAuthUser.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 27.03.2024.
//

import TinyAsyncRedux


class OnAuthUser: Middleware {
    private let cryptoManager: CryptoManagerProtocol

    init(cryptoManager: CryptoManagerProtocol) {
        self.cryptoManager = cryptoManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .authUser(tokenType, pin, user) = action else {
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
                                                           serial: user.tokenSerial, pin: pin) {
                        let certs = try await cryptoManager.enumerateCerts()
                        guard certs.contains(where: {$0.id == user.certId}) else {
                            throw CryptoManagerError.noSuitCert
                        }
                    }
                    continuation.yield(.selectUser(user))
                    continuation.yield(.savePin(pin, user.tokenSerial, true))
                    continuation.yield(.hideSheet)
                    continuation.yield(.updatePin(""))
                } catch CryptoManagerError.incorrectPin(let attemptsLeft) {
                    continuation.yield(.showPinInputError("Неверный PIN-код. Осталось попыток: \(attemptsLeft)"))
                    continuation.yield(.deletePin(user.tokenSerial))
                } catch CryptoManagerError.nfcStopped {
                } catch let error as CryptoManagerError {
                    continuation.yield(.showAlert(AppAlert(from: error)))
                }
            }
        }
    }
}
