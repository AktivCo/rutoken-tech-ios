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
    var helper: FileHelperMock!
    var source: FileSourceMock!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        helper = FileHelperMock()
        source = FileSourceMock()
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
        source.getUrlResult = { file, dir in
            XCTAssertEqual(file, "documents.json")
            XCTAssertEqual(dir, .documents)
            return docUrl
        }
        helper.readFileCallback = { url in
            XCTAssertEqual(url, docUrl)
            return try BankDocument.jsonEncoder.encode([doc])
        }

        helper.clearDirCallback = { _ in exp1.fulfill() }

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
        source.getUrlResult = { file, dir in
            XCTAssertEqual(file, "documents.json")
            XCTAssertEqual(dir, .documents)
            return docUrl
        }
        helper.readFileCallback = { url in
            XCTAssertEqual(url, docUrl)
            return try BankDocument.jsonEncoder.encode([document, anotherDocument])
        }

        try manager!.reset()
        let documents = try awaitPublisherUnwrapped(manager!.documents)
        XCTAssertTrue(documents.contains(document))
        XCTAssertTrue(documents.contains(anotherDocument))
        XCTAssertEqual(documents.count, 2)
    }

    func testResetTempDirectoryClearTempDirError() throws {
        let error = DocumentManagerError.general("")
        helper.clearDirCallback = { _ in throw error }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            XCTAssertThrowsError(try manager.reset()) {
                XCTAssertEqual($0 as? DocumentManagerError, error)
            }
        }
    }

    func testResetTempDirectoryEmptyList() throws {
        helper.readFileCallback = { _ in Data("[]".utf8) }

        let docs = try awaitPublisherUnwrapped(manager.documents.dropFirst()) {
            XCTAssertNoThrow(try manager.reset())
        }

        XCTAssertTrue(docs.isEmpty)
    }

    func testResetTempDirectoryGetUrlError() throws {
        source.getUrlResult = { _, _ in nil}

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
        helper.readFileCallback = { _ in throw error }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            XCTAssertThrowsError(try manager.reset()) {
                XCTAssertEqual($0 as? DocumentManagerError, error)
            }
        }
    }

    func testResetTmpDirectoryBadJson() throws {
        helper.readFileCallback = { _ in Data("{}".utf8) }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            XCTAssertThrowsError(try manager.reset())
        }
    }
}
