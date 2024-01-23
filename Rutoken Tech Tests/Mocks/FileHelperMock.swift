//
//  FileHelperMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 25.01.2024.
//

import Foundation

@testable import Rutoken_Tech


struct FileHelperMock: FileHelperProtocol {
    func getContent(of file: RtFile) -> String? {
        getContentResult
    }

    var getContentResult: String?
}
