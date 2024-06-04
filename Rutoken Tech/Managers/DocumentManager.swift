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
    func initBackup(docs: [DocumentData]) throws
    func reset() throws
    func readDocsFromBundle() throws -> [DocBundleData]
    func writeDocument(fileName: String, data: Data) throws -> URL
    func readDocument(with name: String) throws -> BankFileContent
    func markAsArchived(documentName: String) throws
}

struct DocumentData {
    let name: String
    let content: Data
}

struct DocBundleData {
    let doc: DocumentData
    let action: BankDocument.ActionType
}

enum DocumentDir: String {
    case core = "BankCoreDir"
    case temp = "BankTempDir"
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
    private let documentsUrl: URL

    init?(helper: FileHelperProtocol) {
        self.fileHelper = helper

        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        self.documentsUrl = url
    }

    func initBackup(docs: [DocumentData]) throws {
        try fileHelper.clearDir(dirUrl: getUrl(dirType: .core))
        try docs.forEach { doc in
            try fileHelper.saveFile(content: doc.content, url: getUrl(dirType: .core, name: doc.name))
        }
    }

    func reset() throws {
        do {
            try fileHelper.clearDir(dirUrl: getUrl(dirType: .temp))
            documentsPublisher.send(try readDocsMetaData())
        } catch FileHelperError.generalError(let line, let str) {
            throw DocumentManagerError.general("\(line): \(String(describing: str))")
        }
    }

    func readDocument(with name: String) throws -> BankFileContent {
        do {
            guard let documentModel = documentsPublisher.value.first(where: { $0.name == name }) else {
                throw DocumentManagerError.general("Something went wrong during reading the file")
            }
            let urls = documentModel.urls
            guard !urls.isEmpty else {
                throw DocumentManagerError.general("Something went wrong during reading the file")
            }
            if urls.count == 1 {
                return .singleFile(try fileHelper.readFile(from: urls[0]))
            } else if urls.count == 2 {
                return .fileWithDetachedCMS(file: try fileHelper.readFile(from: urls[0]),
                                            cms: try fileHelper.readFile(from: urls[1]))
            } else {
                throw DocumentManagerError.general("Something went wrong during reading the file")
            }
        } catch FileHelperError.generalError(let line, let str) {
            throw DocumentManagerError.general("\(line): \(String(describing: str))")
        }
    }

    func readDocsFromBundle() throws -> [DocBundleData] {
        let docsInfo = try readDocsMetaData()
        return try docsInfo.map { doc in
            guard let url = Bundle.getUrl(for: doc.name, in: documentsBundleSubdir) else {
                throw DocumentManagerError.general("Something went wrong during reading the file")
            }
            let content = try fileHelper.readFile(from: url)
            return DocBundleData(doc: DocumentData(name: doc.name, content: content),
                                 action: doc.action)
        }
    }

    func writeDocument(fileName: String, data: Data) throws -> URL {
        do {
            let url = getUrl(dirType: .temp, name: fileName)
            try fileHelper.saveFile(content: data, url: url)
            return url
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

    private func getUrl(dirType: DocumentDir, name: String? = nil) -> URL {
        guard let name else {
            return documentsUrl.appendingPathComponent(dirType.rawValue)
        }
        return documentsUrl.appendingPathComponent(dirType.rawValue).appendingPathComponent(name)
    }

    private func readDocsMetaData() throws -> [BankDocument] {
        guard let jsonUrl = Bundle.getUrl(for: documentListFileName, in: documentsBundleSubdir) else {
            throw DocumentManagerError.general("Something went wrong during reset directory")
        }

        let json = try fileHelper.readFile(from: jsonUrl)
        return try BankDocument.jsonDecoder.decode([BankDocument].self, from: json)
    }
}
