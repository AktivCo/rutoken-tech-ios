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
    func resetDirectory() throws
    func readFile(with name: String) throws -> BankFileContent
    func saveToFile(with name: String, data: Data) throws
}

enum DocumentManagerError: Error, Equatable {
    case general(String?)
}

class DocumentManager: DocumentManagerProtocol {
    public var documents: AnyPublisher<[BankDocument], Never> {
        documentsPublisher.eraseToAnyPublisher()
    }

    private let fileHelper: FileHelperProtocol
    private var documentsPublisher = CurrentValueSubject<[BankDocument], Never>([])
    private let documentListFileName = "documents.json"
    private let documentsBundleSubdir = "BankDocuments"

    init?(helper: FileHelperProtocol) {
        self.fileHelper = helper

        do { try resetDirectory() } catch { return nil }
    }

    func resetDirectory() throws {
        try fileHelper.clearTempDir()

        guard let jsonUrl = Bundle.getUrl(for: documentListFileName, in: documentsBundleSubdir) else {
            throw DocumentManagerError.general("Something went wrong during reset directory.")
        }

        let json = try fileHelper.readFile(from: jsonUrl)
        let documents = try BankDocument.jsonDecoder.decode([BankDocument].self, from: json)

        let urls = documents.compactMap { Bundle.getUrl(for: $0.name, in: documentsBundleSubdir) }
        do {
            try fileHelper.copyFilesToTempDir(from: urls)
        } catch FileHelperError.generalError(let line, let str) {
            throw DocumentManagerError.general("\(line): \(String(describing: str))")
        }
        documentsPublisher.send(documents)
    }

    func readFile(with name: String) throws -> BankFileContent {
        do {
            let content = try fileHelper.readDataFromTempDir(filename: name)

            guard let metaDataFile = documentsPublisher.value.first(where: { $0.name == name }) else {
                throw DocumentManagerError.general("Something went wrong during read file.")
            }
            guard let result = BankFileContent(type: metaDataFile.type, content: content) else {
                throw DocumentManagerError.general("Something went wrong during read file.")
            }
            return result
        } catch FileHelperError.generalError(let line, let str) {
            throw DocumentManagerError.general("\(line): \(String(describing: str))")
        }
    }

    func saveToFile(with name: String, data: Data) throws {
    }
}
