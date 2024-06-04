//
//  FileHelperMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 25.01.2024.
//

@testable import Rutoken_Tech

import Foundation


class FileHelperMock: FileHelperProtocol {
    func clearDir(dirUrl: URL) throws { try clearDirCallback(dirUrl) }
    var clearDirCallback: (URL) throws -> Void = { _ in }

    func readFile(from url: URL) throws -> Data { try readFileCallback(url) }
    var readFileCallback: (URL) throws -> Data = { _ in Data() }

    func saveFile(content: Data, url: URL) throws {
        try saveFileCallback(content, url)
    }
    var saveFileCallback: (Data, URL) throws -> Void = { _, _ in }
}

