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
                    let file = try documentManager.readFile(with: documentName)
                    guard case let .singleFile(document) = file else {
                        continuation.yield(.showAlert(.unknownError))
                        return
                    }
                    try await cryptoManager.withToken(connectionType: connectionType, serial: serial, pin: pin) {
                        let cms = try cryptoManager.signDocument(document, certId: certId)
                        let cmsData = Data(cms.utf8)

                        try documentManager.saveToFile(fileName: documentName + ".sig", data: cmsData)
                        try documentManager.markAsArchived(documentName: documentName)

                        continuation.yield(.updateUrlsForCurrentDoc(documentName: documentName, action: .sign, inArchive: true))

                        continuation.yield(.hideSheet)
                        continuation.yield(.showAlert(.documentSigned))
                    }
                } catch CryptoManagerError.incorrectPin(let attemptsLeft) {
                    continuation.yield(.showPinInputError("Неверный PIN-код. Осталось попыток: \(attemptsLeft)"))
                } catch CryptoManagerError.nfcStopped {
                } catch let error as CryptoManagerError {
                    continuation.yield(.showAlert(AppAlert(from: error)))
                }
            }
        }
    }
}
