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

        // This is neccessary to DocumentManager init
        helper.readFileCallback = { _ in "[]".data(using: .utf8)! }
        manager = DocumentManager(helper: helper)

        dataToSave = "Data to save".data(using: .utf8)

        let name = "Платежное \"поручение\" №121"
        let amount: Int = 35600
        let company = "ОАО \"Нефтегаз\""
        let paymentDay = Date()
        document = BankDocument(name: name,
                                action: .sign,
                                amount: amount,
                                companyName: company,
                                paymentDay: paymentDay)
    }

    func testSaveToFileSuccess() throws {
        let doc2 = BankDocument(name: document.name + "2",
                                action: .encrypt,
                                amount: document.amount + 5000,
                                companyName: document.companyName,
                                paymentDay: document.paymentDay)

        helper.readFileCallback = { url in
            XCTAssertEqual(Bundle.getUrl(for: "documents.json", in: "BankDocuments"), url)
            return try BankDocument.jsonEncoder.encode([self.document, doc2])
        }
        let documentFileName = document.name + ".sig"
        helper.saveFileToTempDirCallback = { fileName, _ in
            XCTAssertEqual(fileName, documentFileName)
        }
        manager = DocumentManager(helper: helper)

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            try manager.saveToFile(documentName: document.name, fileName: documentFileName, data: dataToSave!)
        }
    }

    func testSaveToFileError() throws {
        helper.saveFileToTempDirCallback = { _, _ in
            throw FileHelperError.generalError(33, "File helper error")
        }

        assertError(try manager.saveToFile(documentName: document.name, fileName: document.name + ".sig", data: dataToSave!),
                    throws: DocumentManagerError.general("33: \(String(describing: Optional("File helper error")))"))
    }
}
