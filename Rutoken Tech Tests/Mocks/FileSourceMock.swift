//
//  FileSourceMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 28.06.2024.
//

import Foundation

@testable import Rutoken_Tech


class FileSourceMock: FileSourceProtocol {
    func getUrl(for fileName: String, in sourceDir: SourceDir) -> URL? {
        getUrlResult(fileName, sourceDir)
    }

    var getUrlResult: (String, SourceDir) -> URL? = { _, _ in URL(fileURLWithPath: "") }
}
