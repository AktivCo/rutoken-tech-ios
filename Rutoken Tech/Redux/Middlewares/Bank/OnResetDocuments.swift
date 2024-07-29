//
//  OnResetDocuments.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 25.03.2024.
//

import Foundation

import TinyAsyncRedux


class OnResetDocuments: Middleware {
    private let manager: DocumentManagerProtocol

    init(manager: DocumentManagerProtocol) {
        self.manager = manager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case .resetDocuments = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            Task {
                defer {
                    continuation.finish()
                }

                try? await Task.sleep(for: .seconds(3.6))
                do {
                    try manager.reset()
                } catch {
                    continuation.yield(.handleError(error))
                }
            }
        }
    }
}
