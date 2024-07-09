//
//  ReadDocsFromBundleTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 14.06.2024.
//

import XCTest

@testable import Rutoken_Tech


class DocumentManagerReadDocsFromBundleTests: XCTestCase {
    var manager: DocumentManager!
    var helper: RtMockFileHelperProtocol!
    var source: FileSourceMock!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        helper = RtMockFileHelperProtocol()
        source = FileSourceMock()
        manager = DocumentManager(helper: helper, fileSource: source)
    }

    func testReadDocsFromBundleSuccess() throws {
        let doc = BankDocument(name: "Инкассовое поручение №00981.pdf",
                     action: .encrypt,
                     amount: 45000,
                     companyName: "ООО «Тренд Хоум»",
                     paymentTime: Date())

        let docUrl = URL(fileURLWithPath: "documents.json")
        let getUrlExp = expectation(description: "Get URL expectation")
        getUrlExp.expectedFulfillmentCount = 2
        source.getUrlResult = { file, _ in
            defer { getUrlExp.fulfill() }
            switch file {
            case "documents.json": return docUrl
            default: return URL(fileURLWithPath: "")
            }
        }

        let readFileExp = expectation(description: "Read file expectation")
        readFileExp.expectedFulfillmentCount = 2
        helper.mocked_readFile = { url in
            defer { readFileExp.fulfill() }
            switch url {
            case docUrl: return try BankDocument.jsonEncoder.encode([doc])
            default: return Data(repeating: 0x07, count: 7)
            }
        }
        let result = try manager.readDocsFromBundle()

        result.forEach {
            XCTAssertEqual($0.action, doc.action)
            XCTAssertEqual($0.doc.name, doc.name)
        }

        wait(for: [getUrlExp, readFileExp], timeout: 0.3)
    }

    func testReadDocsFromBundleGetUrlForDocError() throws {
        source.getUrlResult = { _, _ in
            return nil
        }

        assertError(try manager.readDocsFromBundle(), throws: DocumentManagerError.general("Something went wrong during reset directory"))
    }

    func testReadDocsFromBundleReadFileDocError() throws {
        let error = FileHelperError.generalError(15, "FileHelperError")
        helper.mocked_readFile = { _ in
            throw error
        }

        assertError(try manager.readDocsFromBundle(), throws: error)
    }

    func testReadDocsFromBundleNoDocsSuccess() throws {
        helper.mocked_readFile = { _ in
            return try BankDocument.jsonEncoder.encode([BankDocument]())
        }

        let result = try manager.readDocsFromBundle()
        XCTAssertEqual(result.count, 0)
    }

    func testReadDocsFromBundleBadJson() throws {
        helper.mocked_readFile = { _ in
            Data("[[]".utf8)
        }
        XCTAssertThrowsError(try manager.readDocsFromBundle())
    }

    func testReadDocsFromBundleGetUrlForFileError() throws {
        let doc = BankDocument(name: "Инкассовое поручение №00981.pdf",
                     action: .encrypt,
                     amount: 45000,
                     companyName: "ООО «Тренд Хоум»",
                     paymentTime: Date())

        let docUrl = URL(fileURLWithPath: "documents.json")
        let getUrlExp = expectation(description: "Get URL expectation")
        getUrlExp.expectedFulfillmentCount = 2
        source.getUrlResult = { file, _ in
            defer { getUrlExp.fulfill() }
            switch file {
            case "documents.json": return docUrl
            default: return nil
            }
        }

        helper.mocked_readFile = { _ in
            try BankDocument.jsonEncoder.encode([doc])
        }

        assertError(try manager.readDocsFromBundle(), throws: DocumentManagerError.general("Something went wrong during reading the file"))

        wait(for: [getUrlExp], timeout: 0.3)
    }

    func testReadDocsFromBundleReadFileError() throws {
        let doc = BankDocument(name: "Инкассовое поручение №00981.pdf",
                     action: .encrypt,
                     amount: 45000,
                     companyName: "ООО «Тренд Хоум»",
                     paymentTime: Date())

        let docUrl = URL(fileURLWithPath: "documents.json")
        let getUrlExp = expectation(description: "Get URL expectation")
        getUrlExp.expectedFulfillmentCount = 2
        source.getUrlResult = { file, dir in
            defer { getUrlExp.fulfill() }
            XCTAssertEqual(dir, .documents)
            switch file {
            case "documents.json": return docUrl
            default: return URL(fileURLWithPath: "")
            }
        }

        let readFileExp = expectation(description: "Get URL expectation")
        readFileExp.expectedFulfillmentCount = 2
        let someError = DocumentManagerError.general("some error")
        helper.mocked_readFile = { url in
            defer { readFileExp.fulfill() }
            switch url {
            case docUrl: return try BankDocument.jsonEncoder.encode([doc])
            default: throw someError
            }
        }

        assertError(try manager.readDocsFromBundle(), throws: someError)

        wait(for: [getUrlExp, readFileExp], timeout: 0.3)
    }
}
