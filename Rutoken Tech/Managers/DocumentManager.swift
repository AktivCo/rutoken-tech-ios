//
//  DocumentManager.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 04.03.2024.
//

import Combine
import Foundation


protocol DocumentManagerProtocol {
    var documents: AnyPublisher<[BankDocument], Never> { get }
    func resetTempDirectory() throws
}

enum DocumentManagerError: Error {
    case general
}


class DocumentManager: DocumentManagerProtocol {
    public var documents: AnyPublisher<[BankDocument], Never> {
        documentsPublisher.eraseToAnyPublisher()
    }

    private let fileHelper: FileHelperProtocol

    private var documentsPublisher = CurrentValueSubject<[BankDocument], Never>([])

    init?(helper: FileHelperProtocol) {
        self.fileHelper = helper

        do { try resetTempDirectory() } catch { return nil }
    }

    func resetTempDirectory() throws {
        try fileHelper.clearTempDir()

        guard let jsonUrl = createBundleUrl(for: fileHelper.documentListFileName,
                                            in: .bankDocuments) else {
            throw DocumentManagerError.general
        }

        let json = try fileHelper.readFile(from: jsonUrl)
        let documents = try BankDocument.jsonDecoder.decode([BankDocument].self, from: json)

        let urls = documents.compactMap { createBundleUrl(for: $0.name, in: .bankDocuments) }
        try fileHelper.copyFilesToTempDir(from: urls)
        documentsPublisher.send(documents)
    }
}
