//
//  FileHelperMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 25.01.2024.
//

@testable import Rutoken_Tech

import Foundation


enum FileHelperMockError: Error {
    case general
}

class FileHelperMock: FileHelperProtocol {
    func clearTempDir() throws { try clearTempDirCallback() }
    var clearTempDirCallback: () throws -> Void = {}

    func readFile(from url: URL) throws -> Data { try readFileCallback(url) }
    var readFileCallback: (URL) throws -> Data = { _ in Data() }

    func saveFileToTempDir(with name: String, content: Data) throws { try saveFileToTempDirCallback(name, content) }
    var saveFileToTempDirCallback: (String, Data) throws -> Void = { _, _ in }

    func copyFilesToTempDir(from source: [URL]) throws { try copyFilesToTempDirCallback(source) }
    var copyFilesToTempDirCallback: ([URL]) throws -> Void = { _ in }
}
