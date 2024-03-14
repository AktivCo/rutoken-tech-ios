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
                if connectionType == .nfc {
                    continuation.yield(.lockNfc)
                }
                defer {
                    if connectionType == .nfc {
                        continuation.yield(.willUnlockNfc)
                    }
                    continuation.yield(.finishGenerateCert)
                    continuation.finish()
                }
                var model = CsrModel.makeDefaultModel()
                model.subjects[.commonName] = commonName

                do {
                    try await cryptoManager.withToken(connectionType: connectionType,
                                                      serial: serial,
                                                      pin: pin) {
                        try await cryptoManager.createCert(for: id, with: model)
                    }

                    continuation.yield(.showAlert(.certGenerated))
                    continuation.yield(.hideSheet)
                } catch CryptoManagerError.nfcStopped {
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
