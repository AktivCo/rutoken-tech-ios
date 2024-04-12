//
//  OnPerformReadCerts.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 21.02.2024.
//

import UIKit

import TinyAsyncRedux


class OnPerformReadCerts: Middleware {
    private let cryptoManager: CryptoManagerProtocol
    private let userManager: UserManagerProtocol

    init(cryptoManager: CryptoManagerProtocol, userManager: UserManagerProtocol) {
        self.cryptoManager = cryptoManager
        self.userManager = userManager
    }

    func getReason(for cert: CertMetaData) async throws -> CertInvalidReason? {
        let users = userManager.listUsers()
        let keys = try await cryptoManager.enumerateKeys()

        if Date() > cert.expiryDate { return .expired } else
        if users.contains(where: { $0.certHash == cert.hash }) { return .alreadyExist } else
        if cert.startDate > Date() { return .notStartedBefore(cert.startDate)} else
        if !keys.contains(where: { $0.ckaId == cert.keyId }) { return .noKeyPair }
        return nil
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

                        var certModels: [CertViewData] = []
                        for cert in certs {
                            certModels.append(CertViewData(from: cert, reason: try await getReason(for: cert)))
                        }

                        continuation.yield(.updateCerts(certModels))
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
