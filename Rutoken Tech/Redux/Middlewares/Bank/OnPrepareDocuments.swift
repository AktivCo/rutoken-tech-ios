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
        guard case let .prepareDocuments(certData) = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            defer {
                continuation.finish()
            }
            do {
                let documents = try documentManager.readDocsFromBundle()
                var processedDocs: [DocumentData] = []

                try documents.forEach { doc in
                    let docContent = doc.doc.content
                    let docName = doc.doc.name
                    switch doc.action {
                    case .verify:
                        let signature: String
                        switch doc.signStatus {
                        case .ok:
                            signature = try cryptoManager.signDocument(docContent, keyFile: .bankKey, certFile: .bankCert, certChain: [.caCert])
                        case .brokenChain:
                            signature = try cryptoManager.signDocument(docContent, keyFile: .bankKey, certFile: .bankCert, certChain: [])
                        case .invalid:
                            let tempSignature = try cryptoManager.signDocument(docContent, keyFile: .bankKey,
                                                                               certFile: .bankCert, certChain: [.caCert])
                            var rawBase64Cms = tempSignature
                                .replacingOccurrences(of: "-----BEGIN CMS-----", with: "")
                                .replacingOccurrences(of: "-----END CMS-----", with: "")
                            rawBase64Cms.removeAll { $0 == "\n" }

                            guard var corruptedCms = Data(base64Encoded: rawBase64Cms) else {
                                continuation.yield(.showAlert(.unknownError))
                                return
                            }
                            corruptedCms[corruptedCms.count - 1] ^= 0x01
                            let rawCorruptedSignature = corruptedCms.base64EncodedString().enumerated().map { (idx, el) -> [Character] in
                                idx > 0 && idx % 64 == 0 ? ["\n", el] : [el]
                            }.joined()
                            signature = "-----BEGIN CMS-----\n" + rawCorruptedSignature + "\n-----END CMS-----"
                        }
                        guard let signatureData = signature.data(using: .utf8) else {
                            throw CryptoManagerError.unknown
                        }
                        processedDocs.append(DocumentData(name: docName + ".sig", content: signatureData))
                        processedDocs.append(DocumentData(name: docName, content: docContent))
                    case .encrypt, .sign:
                        processedDocs.append(DocumentData(name: docName, content: docContent))
                    case .decrypt:
                        let encryptedData = try cryptoManager.encryptDocument(docContent, certData: certData)
                        processedDocs.append(DocumentData(name: docName + ".enc", content: encryptedData))
                    }
                }
                try documentManager.initBackup(docs: processedDocs)
                try documentManager.reset()
            } catch {
                continuation.yield(.handleError(error))
            }
        }
    }
}
