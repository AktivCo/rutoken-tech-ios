//
//  OnPrepareDocuments.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 19.04.2024.
//

import Combine
import Foundation

import TinyAsyncRedux


class OnPrepareDocuments: Middleware {
    private let cryptoManager: CryptoManagerProtocol
    private let documentManager: DocumentManagerProtocol

    private var cancellable = [UUID: AnyCancellable]()

    init(cryptoManager: CryptoManagerProtocol, documentManager: DocumentManagerProtocol) {
        self.cryptoManager = cryptoManager
        self.documentManager = documentManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case .prepareDocuments = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            do {
                try documentManager.resetDirectory()
                let uuid = UUID()
                documentManager.documents
                    .first()
                    .sink { [self] documents in
                        defer {
                            cancellable.removeValue(forKey: uuid)
                            continuation.finish()
                        }
                        do {
                            try documents.filter({ $0.action == .verify }).forEach {
                                guard case let .singleFile(document) = try documentManager.readFile(with: $0.name) else {
                                    return
                                }

                                let signature = try cryptoManager.signDocument(document, keyFile: .rootCaKey, certFile: .rootCaCert)
                                let signatureData = Data(signature.utf8)

                                try documentManager.saveToFile(fileName: $0.name + ".sig", data: signatureData)

                            }
                        } catch {
                            continuation.yield(.showAlert(.unknownError))
                        }
                    }
                    .store(in: &cancellable, for: uuid)
            } catch {
                continuation.yield(.showAlert(.unknownError))
                continuation.finish()
            }
        }
    }
}
