//
//  DocumentManager.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 04.03.2024.
//

import Combine
import Foundation
import PDFKit


protocol DocumentManagerProtocol {
    var documents: AnyPublisher<[BankDocument], Never> { get }
    func resetDirectory() throws
    func readFile(with name: String) throws -> BankFileContent
    func saveToFile(fileName: String, data: Data) throws
    func markAsArchived(documentName: String) throws
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

    init(helper: FileHelperProtocol) {
        self.fileHelper = helper
    }

    func resetDirectory() throws {
        try fileHelper.clearTempDir()

        guard let jsonUrl = Bundle.getUrl(for: documentListFileName, in: documentsBundleSubdir) else {
            throw DocumentManagerError.general("Something went wrong during reset directory")
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
            guard let documentModel = documentsPublisher.value.first(where: { $0.name == name }) else {
                throw DocumentManagerError.general("Something went wrong during reading the file")
            }
            let content = try fileHelper.readDataFromTempDir(filename: name)

            switch documentModel.action {
            case .encrypt, .sign, .decrypt:
                return .singleFile(content)
            case .verify:
                if let signedCms = try? fileHelper.readDataFromTempDir(filename: name + ".sig") {
                    return .fileWithDetachedCMS(file: content, cms: signedCms)
                }
                return .singleFile(content)
            }
        } catch FileHelperError.generalError(let line, let str) {
            throw DocumentManagerError.general("\(line): \(String(describing: str))")
        }
    }

    func saveToFile(fileName: String, data: Data) throws {
        do {
            try fileHelper.saveFileToTempDir(with: fileName, content: data)
        } catch FileHelperError.generalError(let line, let str) {
            throw DocumentManagerError.general("\(line): \(String(describing: str))")
        }
    }

    func markAsArchived(documentName: String) throws {
        var documents = documentsPublisher.value
        guard let index = documents.firstIndex(where: { $0.name == documentName }) else {
            throw DocumentManagerError.general("Something went wrong during reading the file")
        }
        documents[index].inArchive = true
        documents[index].dateOfChange = Date()
        documentsPublisher.send(documents)
    }
}
