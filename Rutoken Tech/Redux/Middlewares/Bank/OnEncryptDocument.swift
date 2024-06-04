//
//  OnEncryptDocument.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 13.05.2024.
//

import TinyAsyncRedux


class OnEncryptDocument: Middleware {
    private let cryptoManager: CryptoManagerProtocol
    private let documentManager: DocumentManagerProtocol

    init(cryptoManager: CryptoManagerProtocol, documentManager: DocumentManagerProtocol) {
        self.cryptoManager = cryptoManager
        self.documentManager = documentManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .encryptDocument(documentName) = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            Task {
                defer {
                    continuation.finish()
                }
                do {
                    let file = try documentManager.readDocument(with: documentName)
                    guard case let .singleFile(content) = file else {
                        continuation.yield(.showAlert(.unknownError))
                        return
                    }
                    let encryptedData = try cryptoManager.encryptDocument(content, certFile: .bankCert)
                    let encryptedDocUrl = try documentManager.writeDocument(fileName: documentName + ".enc", data: encryptedData)
                    try documentManager.markAsArchived(documentName: documentName)

                    _ = documentManager.documents.first().sink { docs in
                        let updatedDoc = docs.first { documentName == $0.name }
                        continuation.yield(.updateUrlsForShare([encryptedDocUrl]))
                        continuation.yield(.updateCurrentDoc(updatedDoc, .singleFile(encryptedData)))
                        continuation.yield(.hideSheet)
                        continuation.yield(.showAlert(.documentEncrypted))
                    }
                } catch let error as CryptoManagerError {
                    continuation.yield(.showAlert(AppAlert(from: error)))
                } catch {
                    continuation.yield(.showAlert(.unknownError))
                }
            }
        }
    }
}
