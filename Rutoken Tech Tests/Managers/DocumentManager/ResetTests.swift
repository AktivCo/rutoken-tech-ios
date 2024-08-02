//
//  ResetTests.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 11.03.2024.
//

import XCTest

@testable import Rutoken_Tech


class DocumentManagerResetTests: XCTestCase {
    var manager: DocumentManager!
    var helper: RtMockFileHelperProtocol!
    var source: RtMockFileSourceProtocol!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        helper = RtMockFileHelperProtocol()
        source = RtMockFileSourceProtocol()
        manager = DocumentManager(helper: helper, fileSource: source)
    }

    func testResetTempDirectorySuccess() throws {
        let name = "Платежное \"поручение\" №121"
        let amount: Int = 35600
        let company = "ОАО \"Нефтегаз\""
        let paymentDay = Date()

        let doc = BankDocument(name: name,
                               action: .encrypt,
                               amount: amount,
                               companyName: company,
                               paymentTime: paymentDay)

        let exp1 = XCTestExpectation(description: "Clear temp directory")
        let docUrl = URL(fileURLWithPath: "documents.json")
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { file, dir in
            XCTAssertEqual(file, "documents.json")
            XCTAssertEqual(dir, .documents)
            return docUrl
        }
        helper.mocked_readFile_fromUrlURL_Data = { url in
            XCTAssertEqual(url, docUrl)
            return try BankDocument.jsonEncoder.encode([doc])
        }

        helper.mocked_clearDir_dirUrlURL_Void = { _ in exp1.fulfill() }

        let docs = try awaitPublisherUnwrapped(manager.documents.dropFirst()) {
            XCTAssertNoThrow(try manager.reset())
        }

        wait(for: [exp1], timeout: 0.3)
        XCTAssertEqual(docs, [doc])
    }

    func testResetTempDirectorySeveralDocumentsSuccess() throws {
        let document = BankDocument(name: "Платежное поручение №0543.pdf",
                                action: .sign,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentTime: Date())

        let anotherDocument = BankDocument(name: "Платежное поручение №03423543.pdf",
                                action: .verify,
                                amount: 3561100,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentTime: Date())

        let docUrl = URL(fileURLWithPath: "documents.json")
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { file, dir in
            XCTAssertEqual(file, "documents.json")
            XCTAssertEqual(dir, .documents)
            return docUrl
        }
        helper.mocked_readFile_fromUrlURL_Data = { url in
            XCTAssertEqual(url, docUrl)
            return try BankDocument.jsonEncoder.encode([document, anotherDocument])
        }
        helper.mocked_clearDir_dirUrlURL_Void = { _ in }

        try manager!.reset()
        let documents = try awaitPublisherUnwrapped(manager!.documents)
        XCTAssertTrue(documents.contains(document))
        XCTAssertTrue(documents.contains(anotherDocument))
        XCTAssertEqual(documents.count, 2)
    }

    func testResetTempDirectoryClearTempDirError() throws {
        let error = DocumentManagerError.general("")
        helper.mocked_clearDir_dirUrlURL_Void = { _ in throw error }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            XCTAssertThrowsError(try manager.reset()) {
                XCTAssertEqual($0 as? DocumentManagerError, error)
            }
        }
    }

    func testResetTempDirectoryEmptyList() throws {
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        helper.mocked_readFile_fromUrlURL_Data = { _ in Data("[]".utf8) }
        helper.mocked_clearDir_dirUrlURL_Void = { _ in }

        let docs = try awaitPublisherUnwrapped(manager.documents.dropFirst()) {
            XCTAssertNoThrow(try manager.reset())
        }

        XCTAssertTrue(docs.isEmpty)
    }

    func testResetTempDirectoryGetUrlError() throws {
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in nil }
        helper.mocked_clearDir_dirUrlURL_Void = { _ in }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            XCTAssertThrowsError(try manager.reset()) {
                guard case .general = $0 as? DocumentManagerError else {
                    XCTFail("Enexpected error is received")
                    return
                }
            }
        }
    }

    func testResetTempDirectoryReadFileError() throws {
        let error = DocumentManagerError.general("")
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        helper.mocked_readFile_fromUrlURL_Data = { _ in throw error }
        helper.mocked_clearDir_dirUrlURL_Void = { _ in }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            XCTAssertThrowsError(try manager.reset()) {
                XCTAssertEqual($0 as? DocumentManagerError, error)
            }
        }
    }

    func testResetTmpDirectoryBadJson() throws {
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        helper.mocked_readFile_fromUrlURL_Data = { _ in Data("{}".utf8) }
        helper.mocked_clearDir_dirUrlURL_Void = { _ in }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            XCTAssertThrowsError(try manager.reset())
        }
    }
}
