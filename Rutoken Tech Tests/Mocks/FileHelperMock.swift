//
//  FileHelperMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 25.01.2024.
//

@testable import Rutoken_Tech


class FileHelperMock: FileHelperProtocol {
    func getContent(of file: RtFile) -> String? {
        getContentResult
    }

    var getContentResult: String?
}
