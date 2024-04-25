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
                let content = try documentManager.readFile(with: doc.name)
                continuation.yield(.updateCurrentDoc(doc, content))
                continuation.yield(.updateUrlsForCurrentDoc(documentName: doc.name, action: doc.action, inArchive: doc.inArchive))
            } catch {
                continuation.yield(.showAlert(.unknownError))
            }
        }
    }
}
