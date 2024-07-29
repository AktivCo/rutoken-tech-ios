//
//  OnGenerateQrCode.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 04.07.2024.
//

import TinyAsyncRedux


class OnGenerateQrCode: Middleware {
    private let vcrManager: VcrManagerProtocol

    init(vcrManager: VcrManagerProtocol) {
        self.vcrManager = vcrManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case .generateQrCode = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            Task {
                defer {
                    continuation.finish()
                }
                do {
                    continuation.yield(.updateQrCode(try await vcrManager.generateQrCode()))
                } catch {
                    continuation.yield(.handleError(error))
                }
            }
        }
    }
}
