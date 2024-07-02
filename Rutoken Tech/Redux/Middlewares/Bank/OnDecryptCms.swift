//
//  OnDecryptCms.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 06.06.2024.
//

import Foundation

import TinyAsyncRedux


class OnDecryptCms: Middleware {
    private let cryptoManager: CryptoManagerProtocol
    private let documentManager: DocumentManagerProtocol

    init(cryptoManager: CryptoManagerProtocol, documentManager: DocumentManagerProtocol) {
        self.cryptoManager = cryptoManager
        self.documentManager = documentManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .decryptCms(tokenType, serial, pin, documentName, certId) = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            Task {
                defer {
                    continuation.finish()
                }
                do {
                    let document = try documentManager.readDocument(with: documentName)
                    let connectionType: ConnectionType = tokenType == .nfc ? .nfc : .usb
                    var decryptedData = Data()
                    try await cryptoManager.withToken(connectionType: connectionType, serial: serial, pin: pin) {
                        decryptedData = try cryptoManager.decryptCms(encryptedData: document.data, with: certId)
                    }

                    let decryptedDocUrl = try documentManager.writeDocument(fileName: documentName, data: decryptedData)
                    try documentManager.markAsArchived(documentName: documentName)

                    _ = documentManager.documents.first().sink { docs in
                        let updatedDoc = docs.first { documentName == $0.name }
                        continuation.yield(.updateUrlsForShare([decryptedDocUrl]))
                        continuation.yield(.updateCurrentDoc(updatedDoc, BankFileContent(data: decryptedData)))
                        continuation.yield(.hideSheet)
                        continuation.yield(.showAlert(.documentDecrypted))
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
