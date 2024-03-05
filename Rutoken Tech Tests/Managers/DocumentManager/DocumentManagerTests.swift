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
        manager = DocumentManager(helper: helper)
    }

    func testResetTempDirectorySuccess() throws {
        let exp1 = XCTestExpectation(description: "Clear temp directory")
        let exp2 = XCTestExpectation(description: "Copy files to temp directory")
        helper.clearTempDirCallback = { exp1.fulfill() }
        helper.copyFilesToTempDirCallback = { _ in exp2.fulfill() }

        let docs = try awaitPublisherUnwrapped(manager.documents.dropFirst()) {
            XCTAssertNoThrow(try manager.resetTempDirectory())
        }

        wait(for: [exp1, exp2], timeout: 0.3)
        XCTAssertEqual(docs, [])
    }

    func testResetTempDirectoryClearTempDirError() throws {
        helper.clearTempDirCallback = { throw FileHelperMockError.general }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            XCTAssertThrowsError(try manager.resetTempDirectory()) { error in
                XCTAssertEqual(error as? FileHelperMockError, .general)
            }
        }
    }

    func testResetTempDirectoryCopyFilesError() throws {
        helper.copyFilesToTempDirCallback = { _ in throw FileHelperMockError.general }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            XCTAssertThrowsError(try manager.resetTempDirectory()) { error in
                XCTAssertEqual(error as? FileHelperMockError, .general)
            }
        }
    }
}
