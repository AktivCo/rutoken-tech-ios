//
//  ReadDocsFromBundleTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 14.06.2024.
//

import XCTest

@testable import Rutoken_Tech


class ReadDocsFromBundleTests: XCTestCase {
    var manager: DocumentManager!
    var helper: FileHelperMock!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        helper = FileHelperMock()
        manager = DocumentManager(helper: helper)
    }

    func testReadDocsFromBundleSuccess() throws {
        let json = """
            [{"name": "Инкассовое поручение №00981.pdf",
            "action": "encrypt",
            "amount": 45000,
            "companyName": "ООО «Тренд Хоум»",
            "paymentTime": "18.02.2023 10:20"},
            {"name": "Инкассовое поручение №15.pdf",
            "action": "decrypt",
            "amount": 700350,
            "companyName": "АО «Тандер Боут»",
            "paymentTime": "30.08.2023 12:54"}]
"""
        helper.readFileCallback = { _ in
            return json.data(using: .utf8)!
        }

        let result = try manager.readDocsFromBundle()
        let data = try BankDocument.jsonDecoder.decode([BankDocument].self, from: Data(json.utf8))

        data.forEach { data in
            XCTAssert(result.contains { doc in
                doc.doc.name == data.name && doc.action == data.action
            })
        }
    }

    func testReadDocsFromBundleNoDocsSuccess() throws {
        let json = """
                []
"""
        helper.readFileCallback = { _ in
            return json.data(using: .utf8)!
        }

        let result = try manager.readDocsFromBundle()
        XCTAssertEqual(result.count, 0)
    }


    func testReadDocsFromBundleReadFileError() throws {
        let error = FileHelperError.generalError(15, "FileHelperError")
        helper.readFileCallback = { _ in
            throw error
        }

        assertError(try manager.readDocsFromBundle(), throws: error)
    }

    func testReadDocsFromBundleBadJson() throws {
        let badJson = """
            [[{"name": "Инкассовое поручение №00981.pdf",
            "action": "encrypt",
            "amount": 45000,
            "companyName": "ООО «Тренд Хоум»",
            "paymentTime": "18.02.2023 10:20"},
            {"name": "Инкассовое поручение №15.pdf",
            "action": "decrypt",
            "amount": 700350,
            "companyName": "АО «Тандер Боут»",
            "paymentTime": "30.08.2023 12:54"}]
"""
        helper.readFileCallback = { _ in
            return badJson.data(using: .utf8)!
        }
        XCTAssertThrowsError(try manager.readDocsFromBundle())
    }

    func testReadDocsFromBundleWrongDocumentNameError() throws {
        let json = """
            [{"name": "wrongdocname",
            "action": "encrypt",
            "amount": 45000,
            "companyName": "ООО «Тренд Хоум»",
            "paymentTime": "18.02.2023 10:20"}]
"""
        helper.readFileCallback = { _ in
            return json.data(using: .utf8)!
        }

        let error = DocumentManagerError.general("Something went wrong during reading the file")
        assertError(try manager.readDocsFromBundle(), throws: error)
    }
}
