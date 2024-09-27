//
//  OnUnpairVcr.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 01.08.2024.
//

import TinyAsyncRedux


class OnUnpairVcr: Middleware {
    private let vcrManager: VcrManagerProtocol

    init(vcrManager: VcrManagerProtocol) {
        self.vcrManager = vcrManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .unpairVcr(fingerprint) = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            Task {
                defer {
                    continuation.finish()
                }
                do {
                    try vcrManager.unpairVcr(fingerprint: fingerprint)
                } catch {
                    continuation.yield(.handleError(nil, [.showAlert(.unknownError)]))
                }
            }
        }
    }
}
