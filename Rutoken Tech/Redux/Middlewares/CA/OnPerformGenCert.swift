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
