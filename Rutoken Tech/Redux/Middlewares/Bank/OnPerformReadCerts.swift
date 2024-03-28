//
//  OnPerformReadCerts.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 21.02.2024.
//

import UIKit

import RtUiComponents
import TinyAsyncRedux


class OnPerformReadCerts: Middleware {
    private let cryptoManager: CryptoManagerProtocol

    init(cryptoManager: CryptoManagerProtocol) {
        self.cryptoManager = cryptoManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .readCerts(connectionType, pin) = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            Task {
                defer {
                    continuation.finish()
                }

                continuation.yield(.updateCerts([]))
                let tokenInterface: ConnectionType = connectionType == .nfc ? .nfc : .usb
                do {
                    try await self.cryptoManager.withToken(connectionType: tokenInterface,
                                                           serial: nil, pin: pin) {
                        let certs = try await self.cryptoManager.enumerateCerts()
                        guard !certs.isEmpty else {
                            continuation.yield(.showAlert(.noCerts))
                            return
                        }
                        continuation.yield(.updateCerts(certs))
                        let info = try await cryptoManager.getTokenInfo()
                        continuation.yield(.savePin(pin, info.serial, true))
                        await continuation.yield(.showSheet(false,
                                                            UIDevice.isPhone ? .largePhone : .ipad(width: 540, height: 640),
                                                            CertListView()))
                    }
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
