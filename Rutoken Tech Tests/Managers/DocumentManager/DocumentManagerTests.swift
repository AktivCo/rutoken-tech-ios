//
//  DocumentManager.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 11.03.2024.
//

import XCTest

@testable import Rutoken_Tech


class DocumentManagerTests: XCTestCase {
    var manager: DocumentManager!
    var helper: FileHelperMock!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        helper = FileHelperMock()

        // This is neccessary to DocumentManager init
        helper.readFileCallback = { _ in "[]".data(using: .utf8)! }
        manager = DocumentManager(helper: helper)
    }

    func testResetTempDirectorySuccess() throws {
        let name = "Платежное \"поручение\" №121"
        let action = BankDocument.ActionType.verify
        let amount: Int = 35600
        let company = "ОАО \"Нефтегаз\""
        let paymentDay = Date()

        let doc = BankDocument(name: name,
                               action: action,
                               amount: amount,
                               companyName: company,
                               paymentDay: paymentDay)

        let exp1 = XCTestExpectation(description: "Clear temp directory")
        let exp2 = XCTestExpectation(description: "Copy files to temp directory")
        helper.clearTempDirCallback = { exp1.fulfill() }
        helper.copyFilesToTempDirCallback = { _ in exp2.fulfill() }
        helper.readFileCallback = { url in
            XCTAssertEqual(Bundle.getUrl(for: "documents.json", in: "BankDocuments"), url)
            return try BankDocument.jsonEncoder.encode([doc])
        }

        let docs = try awaitPublisherUnwrapped(manager.documents.dropFirst()) {
            XCTAssertNoThrow(try manager.resetTempDirectory())
        }

        wait(for: [exp1, exp2], timeout: 0.3)
        XCTAssertEqual(docs, [doc])
    }

    func testResetTempDirectoryClearTempDirError() throws {
        let error = FileHelperMockError.general
        helper.clearTempDirCallback = { throw error }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            XCTAssertThrowsError(try manager.resetTempDirectory()) {
                XCTAssertEqual($0 as? FileHelperMockError, error)
            }
        }
    }

    func testResetTempDirectoryEmptyList() throws {
        helper.readFileCallback = { _ in "[]".data(using: .utf8)! }

        let docs = try awaitPublisherUnwrapped(manager.documents.dropFirst()) {
            XCTAssertNoThrow(try manager.resetTempDirectory())
        }

        XCTAssertTrue(docs.isEmpty)
    }

    func testResetTempDirectoryReadFileError() throws {
        let error = FileHelperMockError.general
        helper.readFileCallback = { _ in throw error }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            XCTAssertThrowsError(try manager.resetTempDirectory()) {
                XCTAssertEqual($0 as? FileHelperMockError, error)
            }
        }
    }

    func testResetTmpDirectoryBadJson() throws {
        helper.readFileCallback = { _ in "{}".data(using: .utf8)! }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            XCTAssertThrowsError(try manager.resetTempDirectory())
        }
    }

    func testResetTempDirectoryCopyFilesError() throws {
        let error = FileHelperMockError.general
        helper.copyFilesToTempDirCallback = { _ in throw error }
        helper.readFileCallback = { _ in "[]".data(using: .utf8)! }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            XCTAssertThrowsError(try manager.resetTempDirectory()) {
                XCTAssertEqual($0 as? FileHelperMockError, .general)
            }
        }
    }
}
