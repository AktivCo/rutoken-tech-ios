//
//  WriteDocumentTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 16.04.2024.
//

import XCTest

@testable import Rutoken_Tech


class DocumentManagerWriteDocumentTests: XCTestCase {
    var manager: DocumentManager!
    var helper: FileHelperMock!
    var dataToSave: Data!
    var document: BankDocument!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        helper = FileHelperMock()
        manager = DocumentManager(helper: helper)

        dataToSave = Data("Data to save".utf8)

        let name = "Платежное \"поручение\" №121"
        let amount: Int = 35600
        let company = "ОАО \"Нефтегаз\""
        let paymentDay = Date()
        document = BankDocument(name: name,
                                action: .sign,
                                amount: amount,
                                companyName: company,
                                paymentTime: paymentDay)
    }

    func testWriteDocumentSuccess() throws {
        let documentFileName = document.name + ".sig"
        helper.saveFileCallback = { _, url in
            XCTAssertEqual(url.lastPathComponent, documentFileName)
        }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            _ = try manager.writeDocument(fileName: documentFileName, data: dataToSave!)
        }
    }

    func testWriteDocumentError() throws {
        helper.saveFileCallback = { _, _ in
            throw FileHelperError.generalError(33, "File helper error")
        }

        assertError(try manager.writeDocument(fileName: document.name + ".sig", data: dataToSave!),
                    throws: DocumentManagerError.general("33: \(String(describing: Optional("File helper error")))"))
    }
}
