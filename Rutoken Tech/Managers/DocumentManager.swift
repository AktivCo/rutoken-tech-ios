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
    case filesNotFound
}

class DocumentManager: DocumentManagerProtocol {
    public var documents: AnyPublisher<[BankDocument], Never> {
        documentsPublisher.eraseToAnyPublisher()
    }

    private let fileHelper: FileHelperProtocol

    private var documentsPublisher = CurrentValueSubject<[BankDocument], Never>([])

    init(helper: FileHelperProtocol) {
        self.fileHelper = helper
    }

    func resetTempDirectory() throws {
        try fileHelper.clearTempDir()

        try fileHelper.copyFilesToTempDir(from: [])
        documentsPublisher.send([])
    }
}
