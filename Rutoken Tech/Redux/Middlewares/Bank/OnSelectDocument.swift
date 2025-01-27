//
//  OnSelectDocument.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 17.04.2024.
//

import TinyAsyncRedux


class OnSelectDocument: Middleware {
    private let documentManager: DocumentManagerProtocol

    init(documentManager: DocumentManagerProtocol) {
        self.documentManager = documentManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .selectDocument(doc) = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            defer {
                continuation.finish()
            }
            do {
                let result = try documentManager.readDocument(with: doc.name)
                continuation.yield(.updateCurrentDoc(doc, result))
                continuation.yield(.updateUrlsForShare(doc.urls))
            } catch {
                continuation.yield(.handleError(error))
            }
        }
    }
}
