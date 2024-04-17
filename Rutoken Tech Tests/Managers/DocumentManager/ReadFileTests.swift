//
//  ReadFileTests.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 22.04.2024.
//

import XCTest

@testable import Rutoken_Tech


class DocumentManagerReadFileTests: XCTestCase {
    var manager: DocumentManager!
    var helper: FileHelperMock!
    var document: BankDocument!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        helper = FileHelperMock()
        helper.readFileCallback = { _ in "[]".data(using: .utf8)! }
        manager = DocumentManager(helper: helper)
    }

    func testReadFileSuccessFileToSign() throws {
        document = BankDocument(name: "Платежное \"поручение\" №121",
                                action: .sign,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentDay: Date())
        helper.readFileCallback = { _ in return try BankDocument.jsonEncoder.encode([self.document]) }

        manager = DocumentManager(helper: helper)

        let data = Data(repeating: 0x07, count: 777)
        helper.readDataFromTempDirCallback = { name in
            XCTAssertEqual(name, self.document.name)
            return data
        }
        let result = try manager.readFile(with: document.name)
        guard case .singleFile(let documentData) = result else {
            XCTFail("Something went wrong with receiving of the file")
            return
        }

        XCTAssertEqual(documentData, data)
    }

    func testReadFileSuccessFileToVerify() throws {
        let exp = XCTestExpectation(description: "readDataFromTempDir")
        exp.expectedFulfillmentCount = 2
        document = BankDocument(name: "Платежное \"поручение\" №121",
                                action: .verify,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentDay: Date())
        helper.readFileCallback = { _ in return try BankDocument.jsonEncoder.encode([self.document]) }

        manager = DocumentManager(helper: helper)

        let data = Data(repeating: 0x07, count: 777)
        let cms = Data(repeating: 0x07, count: 77)
        var readFileData = data
        var fileName = document.name
        helper.readDataFromTempDirCallback = { name in
            exp.fulfill()

            XCTAssertEqual(name, fileName)
            fileName += ".sig"

            let temp = readFileData
            readFileData = cms
            return temp
        }
        let result = try manager.readFile(with: document.name)
        guard case .fileWithDetachedCMS(let documentData, cms: let sig) = result else {
            XCTFail("Something went wrong with receiving of the file")
            return
        }

        XCTAssertEqual(documentData, data)
        XCTAssertEqual(sig, cms)
        wait(for: [exp], timeout: 0.3)
    }

    func testReadFileSuccessFileToPrepareDocumentToVerify() throws {
        let exp = XCTestExpectation(description: "readDataFromTempDir")
        exp.expectedFulfillmentCount = 2
        document = BankDocument(name: "Платежное \"поручение\" №121",
                                action: .verify,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentDay: Date())
        helper.readFileCallback = { _ in return try BankDocument.jsonEncoder.encode([self.document]) }

        manager = DocumentManager(helper: helper)

        let data = Data(repeating: 0x07, count: 777)
        helper.readDataFromTempDirCallback = { name in
            exp.fulfill()
            if name.contains(".sig") {
                throw FileHelperError.generalError(1, nil)
            }
            return data
        }
        let result = try manager.readFile(with: document.name)
        guard case .singleFile(let documentData) = result else {
            XCTFail("Something went wrong with receiving of the file")
            return
        }

        XCTAssertEqual(documentData, data)
        wait(for: [exp], timeout: 0.3)
    }

    func testReadFileSuccessFileToEncrypt() throws {
        document = BankDocument(name: "Платежное \"поручение\" №121",
                                action: .encrypt,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentDay: Date())
        helper.readFileCallback = { _ in return try BankDocument.jsonEncoder.encode([self.document]) }

        manager = DocumentManager(helper: helper)

        let data = Data(repeating: 0x07, count: 777)
        helper.readDataFromTempDirCallback = { _ in
            return data
        }
        let result = try manager.readFile(with: document.name)
        guard case .singleFile(let documentData) = result else {
            XCTFail("Something went wrong with receiving of the file")
            return
        }

        XCTAssertEqual(documentData, data)
    }

    func testReadFileSuccessFileToDecrypt() throws {
        document = BankDocument(name: "Платежное \"поручение\" №121",
                                action: .decrypt,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentDay: Date())
        helper.readFileCallback = { _ in return try BankDocument.jsonEncoder.encode([self.document]) }

        manager = DocumentManager(helper: helper)

        let encodedFile = "some text".data(using: .utf8)!.base64EncodedString().data(using: .utf8)!
        helper.readDataFromTempDirCallback = { _ in
            encodedFile
        }
        let result = try manager.readFile(with: document.name)
        guard case .singleFile(let base64) = result else {
            XCTFail("Something went wrong with receiving of the file")
            return
        }

        XCTAssertEqual(base64, encodedFile)
    }

    func testReadFileNoDocument() throws {
        XCTAssertThrowsError(try manager.readFile(with: "some name")) {
            XCTAssertEqual($0 as? DocumentManagerError, DocumentManagerError.general("Something went wrong during reading the file"))
        }
    }

    func testReadFileReadDataFromTempDirError() throws {
        document = BankDocument(name: "Платежное \"поручение\" №121",
                                action: .sign,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentDay: Date())
        helper.readFileCallback = { _ in return try BankDocument.jsonEncoder.encode([self.document]) }
        manager = DocumentManager(helper: helper)

        let error = FileHelperError.generalError(1, nil)
        helper.readDataFromTempDirCallback = { _ in
            throw error
        }
        XCTAssertThrowsError(try manager.readFile(with: document.name)) { error in
            guard case DocumentManagerError.general = error else {
                XCTFail("Something went wrong with receiving of the file")
                return
            }
        }
    }
}
