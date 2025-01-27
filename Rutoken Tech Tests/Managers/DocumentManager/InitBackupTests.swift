//
//  InitBackupTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 14.06.2024.
//

import XCTest

@testable import Rutoken_Tech


class DocumentManagerInitBackupTests: XCTestCase {
    var manager: DocumentManager!

    var helper: RtMockFileHelperProtocol!
    var source: RtMockFileSourceProtocol!

    var docsUrl: URL!
    var documentData: [DocumentData]!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        docsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        documentData = [
            DocumentData(name: "document1", content: Data(repeating: 55, count: 19)),
            DocumentData(name: "document2", content: Data(repeating: 19, count: 55))
        ]

        helper = RtMockFileHelperProtocol()
        source = RtMockFileSourceProtocol()

        manager = DocumentManager(helper: helper, fileSource: source)
    }

    func testInitBackupSuccess() throws {
        let exp = XCTestExpectation(description: "Clear core directory")
        var tempDocs = documentData!
        helper.mocked_saveFile_contentData_urlURL_Void = { [self] data, url in
            XCTAssertFalse(tempDocs.isEmpty)
            XCTAssertTrue(tempDocs.contains { doc in
                doc.content == data && docsUrl.appendingPathComponent("BankCoreDir").appendingPathComponent(doc.name) == url
            })
            tempDocs.removeAll { doc in
                doc.content == data && docsUrl.appendingPathComponent("BankCoreDir").appendingPathComponent(doc.name) == url
            }
        }
        helper.mocked_clearDir_dirUrlURL_Void = { _ in
            exp.fulfill()
        }
        try manager.initBackup(docs: documentData)
        wait(for: [exp], timeout: 0.3)
    }

    func testInitBackupEmptyDocs() throws {
        let exp1 = XCTestExpectation(description: "Clear core directory")
        let exp2 = XCTestExpectation(description: "Save file")
        exp2.isInverted = true
        helper.mocked_clearDir_dirUrlURL_Void = { _ in
            exp1.fulfill()
        }
        helper.mocked_saveFile_contentData_urlURL_Void = { _, _ in
            exp2.fulfill()
        }
        try manager.initBackup(docs: [])
        wait(for: [exp1, exp2], timeout: 0.3)
    }

    func testInitBackupFileHelperError() throws {
        let error = FileHelperError.generalError(32, "FileHelper error")
        helper.mocked_saveFile_contentData_urlURL_Void = { _, _ in
            throw error
        }
        helper.mocked_clearDir_dirUrlURL_Void = { _ in }
        assertError(try manager.initBackup(docs: documentData), throws: error)
    }

}
