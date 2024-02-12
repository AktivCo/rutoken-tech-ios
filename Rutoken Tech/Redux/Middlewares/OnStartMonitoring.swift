//
//  OnStartMonitoring.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 12.02.2024.
//

import TinyAsyncRedux


class OnStartMonitoring: Middleware {
    private let cryptoManager: CryptoManagerProtocol

    init(cryptoManager: CryptoManagerProtocol) {
        self.cryptoManager = cryptoManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case .appLoaded = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            defer {
                continuation.finish()
            }

            do {
                try cryptoManager.startMonitoring()
            } catch {
                continuation.yield(.showAlert(.unknownError))
            }
        }
    }
}

