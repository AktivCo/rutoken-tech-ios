//
//  OnInitCooldownNfc.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 13.03.2024.
//

import Foundation

import TinyAsyncRedux


class OnInitCooldownNfc: Middleware {
    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case .willUnlockNfc = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            Task {
                try? await Task.sleep(for: .seconds(5))
                continuation.yield(.unlockNfc)
                continuation.finish()
            }
        }
    }
}
