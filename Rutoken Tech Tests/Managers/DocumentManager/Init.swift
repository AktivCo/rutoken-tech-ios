//
//  Init.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 23.04.2024.
//

import XCTest

@testable import Rutoken_Tech


class DocumentManagerInitTests: XCTestCase {
    var helper: FileHelperMock!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        helper = FileHelperMock()
    }

    func testInitSuccess() throws {
        helper.readFileCallback = { url in
            XCTAssertEqual(Bundle.getUrl(for: "documents.json", in: "BankDocuments"), url)
            return "[]".data(using: .utf8)!
        }

        guard let manager = DocumentManager(helper: helper) else {
            XCTFail("Something went wrong during DocumentManager initialization")
            return
        }
        XCTAssertTrue(try awaitPublisherUnwrapped(manager.documents).isEmpty)
    }

    func testInitInvalidDocumentsList() throws {
        helper.readFileCallback = { _ in "".data(using: .utf8)! }
        XCTAssertNil(DocumentManager(helper: helper))
    }

    func testInitSuccessDocuments() throws {
        let document = BankDocument(name: "Платежное поручение №0543.pdf",
                                action: .sign,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentDay: Date())

        helper.readFileCallback = { url in
            XCTAssertEqual(Bundle.getUrl(for: "documents.json", in: "BankDocuments"), url)
            return try BankDocument.jsonEncoder.encode([document])
        }
        helper.copyFilesToTempDirCallback = { urls in
            XCTAssertEqual(urls, [Bundle.getUrl(for: document.name, in: "BankDocuments")])
        }
        guard let manager = DocumentManager(helper: helper) else {
            XCTFail("Something went wrong during DocumentManager initialization")
            return
        }
        let documents = try awaitPublisherUnwrapped(manager.documents)
        XCTAssertEqual(documents.first, document)
        XCTAssertEqual(documents.count, 1)
    }

    func testInitSuccessSeveralDocuments() throws {
        let document = BankDocument(name: "Платежное поручение №0543.pdf",
                                action: .sign,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentDay: Date())

        let anotherDocument = BankDocument(name: "Платежное поручение №03423543.pdf",
                                action: .verify,
                                amount: 3561100,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentDay: Date())

        helper.readFileCallback = { url in
            XCTAssertEqual(Bundle.getUrl(for: "documents.json", in: "BankDocuments"), url)
            return try BankDocument.jsonEncoder.encode([document, anotherDocument])
        }
        helper.copyFilesToTempDirCallback = { urls in
            XCTAssertEqual(urls, [Bundle.getUrl(for: document.name, in: "BankDocuments")])
        }
        guard let manager = DocumentManager(helper: helper) else {
            XCTFail("Something went wrong during DocumentManager initialization")
            return
        }
        let documents = try awaitPublisherUnwrapped(manager.documents)
        XCTAssertTrue(documents.contains(document))
        XCTAssertTrue(documents.contains(anotherDocument))
        XCTAssertEqual(documents.count, 2)
    }

    func testInitClearTempDirError() throws {
        helper.clearTempDirCallback = { throw FileHelperError.generalError(1, nil)}
        XCTAssertNil(DocumentManager(helper: helper))
    }

    func testInitReadFileError() throws {
        helper.readFileCallback = { _ in throw FileHelperError.generalError(1, nil)}
        XCTAssertNil(DocumentManager(helper: helper))
    }

    func testInitCopyFilesToTempDirError() throws {
        let document = BankDocument(name: "Платежное поручение №0543.pdf",
                                action: .sign,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentDay: Date())

        helper.readFileCallback = { url in
            XCTAssertEqual(Bundle.getUrl(for: "documents.json", in: "BankDocuments"), url)
            return try BankDocument.jsonEncoder.encode([document])
        }
        helper.copyFilesToTempDirCallback = { _ in throw FileHelperError.generalError(1, nil)}
        XCTAssertNil(DocumentManager(helper: helper))
    }
}
