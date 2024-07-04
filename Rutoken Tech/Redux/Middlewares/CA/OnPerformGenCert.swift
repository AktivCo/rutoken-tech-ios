//
//  OnPerformGenCert.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 25.01.2024.
//

import TinyAsyncRedux


class OnPerformGenCert: Middleware {
    private let cryptoManager: CryptoManagerProtocol

    init(cryptoManager: CryptoManagerProtocol) {
        self.cryptoManager = cryptoManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .generateCert(connectionType, serial, pin, id, commonName) = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            Task {
                defer {
                    continuation.finish()
                }
                var model = CsrModel.makeDefaultModel()
                model.subjects[.commonName] = commonName

                do {
                    try await cryptoManager.withToken(connectionType: connectionType,
                                                      serial: serial,
                                                      pin: pin) {
                        try await cryptoManager.deleteCert(with: id)
                        try await cryptoManager.createCert(for: id, with: model)
                        let certs = try await cryptoManager.enumerateCerts()
                        continuation.yield(.cacheCaCerts(certs))
                    }

                    continuation.yield(.showAlert(.certGenerated))
                    continuation.yield(.hideSheet)
                } catch CryptoManagerError.nfcStopped {
                } catch CryptoManagerError.incorrectPin {
                    continuation.yield(.hideSheet)
                    continuation.yield(.logout)
                    continuation.yield(.showAlert(.pinHasChanged))
                } catch let error as CryptoManagerError {
                    continuation.yield(.showAlert(AppAlert(from: error)))
                } catch {
                    continuation.yield(.showAlert(.unknownError))
                }
            }
        }
    }
}
