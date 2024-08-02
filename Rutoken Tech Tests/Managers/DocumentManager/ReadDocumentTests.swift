//
//  ReadDocumentTests.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 22.04.2024.
//

import XCTest

@testable import Rutoken_Tech


class DocumentManagerReadDocumentTests: XCTestCase {
    var manager: DocumentManager!

    var helper: RtMockFileHelperProtocol!
    var source: RtMockFileSourceProtocol!

    var document: BankDocument!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        helper = RtMockFileHelperProtocol()
        source = RtMockFileSourceProtocol()
        manager = DocumentManager(helper: helper, fileSource: source)
    }

    func testReadDocumentFileToSignSuccess() throws {
        let exp = XCTestExpectation(description: "readDataFromTempDir")
        document = BankDocument(name: "Платежное \"поручение\" №121",
                                action: .sign,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentTime: Date(),
                                inArchive: true)
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        helper.mocked_readFile_fromUrlURL_Data = { _ in
            return try BankDocument.jsonEncoder.encode([self.document])
        }
        helper.mocked_clearDir_dirUrlURL_Void = { _ in }

        try manager.reset()

        let data = Data(repeating: 0x07, count: 777)
        helper.mocked_readFile_fromUrlURL_Data = { url in
            exp.fulfill()
            XCTAssertEqual(url.lastPathComponent, self.document.name)
            return data
        }
        let result = try manager.readDocument(with: document.name)

        XCTAssertEqual(result.data, data)
    }

    func testReadDocumentFileToVerifySuccess() throws {
        let exp = XCTestExpectation(description: "readDataFromTempDir")
        exp.expectedFulfillmentCount = 2
        document = BankDocument(name: "Платежное \"поручение\" №121",
                                action: .verify,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentTime: Date(),
                                inArchive: true)
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        helper.mocked_readFile_fromUrlURL_Data = { _ in return try BankDocument.jsonEncoder.encode([self.document]) }
        helper.mocked_clearDir_dirUrlURL_Void = { _ in }

        try manager.reset()

        let data = Data(repeating: 0x07, count: 777)
        let cms = Data(repeating: 0x07, count: 77)
        var readFileData = data
        var fileName = document.name
        helper.mocked_readFile_fromUrlURL_Data = { url in
            exp.fulfill()

            XCTAssertEqual(url.lastPathComponent, fileName)
            fileName += ".sig"
            let tmp = readFileData
            readFileData = cms
            return tmp
        }
        let result = try manager.readDocument(with: document.name)

        XCTAssertEqual(result.data, data)
        XCTAssertEqual(result.cmsData, cms)
        wait(for: [exp], timeout: 0.3)
    }

    func testReadDocumentFileToEncryptSuccess() throws {
        document = BankDocument(name: "Платежное \"поручение\" №121",
                                action: .encrypt,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentTime: Date(),
                                inArchive: true
        )
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        helper.mocked_readFile_fromUrlURL_Data = { _ in return try BankDocument.jsonEncoder.encode([self.document]) }
        helper.mocked_clearDir_dirUrlURL_Void = { _ in }

        try manager.reset()

        let data = Data(repeating: 0x07, count: 777)
        helper.mocked_readFile_fromUrlURL_Data = { url in
            XCTAssertEqual(self.document.name, url.lastPathComponent)
            return data
        }
        let result = try manager.readDocument(with: document.name)

        XCTAssertEqual(result.data, data)
    }

    func testReadDocumentFileToDecryptSuccess() throws {
        document = BankDocument(name: "Платежное \"поручение\" №121",
                                action: .decrypt,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentTime: Date(),
                                inArchive: true
        )
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        helper.mocked_readFile_fromUrlURL_Data = { _ in return try BankDocument.jsonEncoder.encode([self.document]) }
        helper.mocked_clearDir_dirUrlURL_Void = { _ in }

        try manager.reset()

        let encodedFile = "some text".data(using: .utf8)!.base64EncodedString().data(using: .utf8)!
        helper.mocked_readFile_fromUrlURL_Data = { url in
            XCTAssertEqual(self.document.name + ".enc", url.lastPathComponent)
            return encodedFile
        }
        let result = try manager.readDocument(with: document.name)

        XCTAssertEqual(result.data, encodedFile)
    }

    func testReadDocumentNoDocument() throws {
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        helper.mocked_readFile_fromUrlURL_Data = { _ in Data("[]".utf8) }
        helper.mocked_clearDir_dirUrlURL_Void = { _ in }

        try manager.reset()
        XCTAssertThrowsError(try manager.readDocument(with: "some name")) {
            XCTAssertEqual($0 as? DocumentManagerError, DocumentManagerError.general("Something went wrong during reading the file"))
        }
    }
}
