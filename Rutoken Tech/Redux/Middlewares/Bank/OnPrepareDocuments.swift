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
    private let documentsManager: DocumentManagerProtocol
    private let fileHelper: FileHelperProtocol
    private let openSslHelper: OpenSslHelperProtocol

    private var cancellable = [UUID: AnyCancellable]()

    init(documentsManager: DocumentManagerProtocol, fileHelper: FileHelperProtocol, openSslHelper: OpenSslHelperProtocol) {
        self.documentsManager = documentsManager
        self.fileHelper = fileHelper
        self.openSslHelper = openSslHelper
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case .prepareDocuments = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            do {
                try documentsManager.resetDirectory()
                guard let bankKeyUrl = Bundle.getUrl(for: RtFile.rootCaKey.rawValue, in: RtFile.subdir),
                      let bankCertUrl = Bundle.getUrl(for: RtFile.rootCaCert.rawValue, in: RtFile.subdir) else {
                    throw CryptoManagerError.unknown
                }
                let bankKey = try fileHelper.readFile(from: bankKeyUrl)
                let bankCert = try fileHelper.readFile(from: bankCertUrl)
                let uuid = UUID()
                documentsManager.documents
                    .first()
                    .sink { [self] documents in
                        defer {
                            cancellable.removeValue(forKey: uuid)
                            continuation.finish()
                        }
                        do {
                            try documents.filter({ $0.action == .verify }).forEach {
                                guard case let .singleFile(content) = try documentsManager.readFile(with: $0.name) else {
                                    return
                                }
                                let signature = try openSslHelper.signCms(for: content, key: bankKey, cert: bankCert)
                                guard let signatureData = signature.data(using: .utf8) else {
                                    throw CryptoManagerError.unknown
                                }
                                try documentsManager.saveToFile(fileName: $0.name + ".sig", data: signatureData)
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
