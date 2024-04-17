//
//  OnCmsVerify.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 15.04.2024.
//

import TinyAsyncRedux


class OnCmsVerify: Middleware {
    private let cryptoManager: CryptoManagerProtocol
    private let documentManager: DocumentManagerProtocol

    init(cryptoManager: CryptoManagerProtocol, documentManager: DocumentManagerProtocol) {
        self.cryptoManager = cryptoManager
        self.documentManager = documentManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .cmsVerify(fileName) = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            Task {
                defer {
                    continuation.finish()
                }
                do {
                    guard case let .fileWithDetachedCMS(content, cms: cms) = try documentManager.readFile(with: fileName) else {
                        continuation.yield(.showAlert(.unknownError))
                        return
                    }
                    try await cryptoManager.verifyCms(signedCms: cms, document: content)
                    try documentManager.markAsArchived(documentName: fileName)
                    continuation.yield(.showAlert(.verifySuccess))
                } catch let error as CryptoManagerError {
                    continuation.yield(.showAlert(AppAlert(from: error)))
                } catch {
                    continuation.yield(.showAlert(.unknownError))
                }
            }
        }
    }
}
