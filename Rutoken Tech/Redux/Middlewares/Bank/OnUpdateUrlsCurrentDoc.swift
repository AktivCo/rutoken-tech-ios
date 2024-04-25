//
//  OnUpdateUrlsCurrentDoc.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 16.05.2024.
//

import Foundation
import TinyAsyncRedux


class OnUpdateUrlsCurrentDoc: Middleware {
    private let documentManager: DocumentManagerProtocol

    init(documentManager: DocumentManagerProtocol) {
        self.documentManager = documentManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .updateUrlsForCurrentDoc(name, action, inArchive) = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            defer {
                continuation.finish()
            }

            var urls = [URL]()

            switch action {
            case .sign:
                var fileExts = [""]
                if inArchive { fileExts.append(".sig") }
                urls = fileExts.compactMap { ext in documentManager.getUrl(for: name + ext) }
            case .verify:
                urls = ["", ".sig"].compactMap { ext in documentManager.getUrl(for: name + ext)}
            case .decrypt:
                urls = [documentManager.getUrl(for: name + "\(inArchive ? "" : ".enc")")].compactMap { $0 }
            case .encrypt:
                urls = [documentManager.getUrl(for: name + "\(inArchive ? ".enc" : "")")].compactMap { $0 }
            }

            continuation.yield(.updateUrlsForShare(urls))
        }
    }
}
