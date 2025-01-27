//
//  OnSignDocument.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 11.04.2024.
//

import Foundation

import TinyAsyncRedux


class OnSignDocument: Middleware {
    private let cryptoManager: CryptoManagerProtocol
    private let documentManager: DocumentManagerProtocol

    init(cryptoManager: CryptoManagerProtocol, documentManager: DocumentManagerProtocol) {
        self.cryptoManager = cryptoManager
        self.documentManager = documentManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .signDocument(tokenType, serial, pin, documentName, certId) = action else {
            return nil
        }

        let connectionType: ConnectionType = tokenType == .nfc ? .nfc : .usb
        return AsyncStream<AppAction> { continuation in
            Task {
                defer {
                    continuation.finish()
                }
                do {
                    let document = try documentManager.readDocument(with: documentName)
                    var cmsData: Data = Data()
                    try await cryptoManager.withToken(connectionType: connectionType, serial: serial, pin: pin) {
                        let cms = try cryptoManager.signDocument(document.data, certId: certId, certChain: [.caCert])
                        cmsData = Data(cms.utf8)
                    }
                    let documentUrl = try documentManager.writeDocument(fileName: documentName, data: document.data)
                    let signatureUrl = try documentManager.writeDocument(fileName: documentName + ".sig", data: cmsData)
                    try documentManager.markAsArchived(documentName: documentName)

                    continuation.yield(.updateUrlsForShare([documentUrl, signatureUrl]))

                    continuation.yield(.hideSheet)
                    continuation.yield(.showAlert(.documentSigned))
                } catch {
                    continuation.yield(.handleError(error))
                }
            }
        }
    }
}
