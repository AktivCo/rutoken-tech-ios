//
//  SaveToFileTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 16.04.2024.
//

import XCTest

@testable import Rutoken_Tech


class DocumentManagerSaveToFileTests: XCTestCase {
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

    func testSaveToFileSuccess() throws {
        let documentFileName = document.name + ".sig"
        helper.saveFileToTempDirCallback = { fileName, _ in
            XCTAssertEqual(fileName, documentFileName)
        }
        manager = DocumentManager(helper: helper)

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            try manager.saveToFile(fileName: documentFileName, data: dataToSave!)
        }
    }

    func testSaveToFileError() throws {
        helper.saveFileToTempDirCallback = { _, _ in
            throw FileHelperError.generalError(33, "File helper error")
        }

        assertError(try manager.saveToFile(fileName: document.name + ".sig", data: dataToSave!),
                    throws: DocumentManagerError.general("33: \(String(describing: Optional("File helper error")))"))
    }
}
