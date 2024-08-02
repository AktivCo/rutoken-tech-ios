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

    var helper: RtMockFileHelperProtocol!
    var source: RtMockFileSourceProtocol!

    var dataToSave: Data!
    var document: BankDocument!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        helper = RtMockFileHelperProtocol()
        source = RtMockFileSourceProtocol()
        manager = DocumentManager(helper: helper, fileSource: source)

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
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        helper.mocked_saveFile_contentData_urlURL_Void = { _, url in
            XCTAssertEqual(url.lastPathComponent, documentFileName)
        }

        try awaitPublisher(manager.documents.dropFirst(), isInverted: true) {
            _ = try manager.writeDocument(fileName: documentFileName, data: dataToSave!)
        }
    }

    func testWriteDocumentError() throws {
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        helper.mocked_saveFile_contentData_urlURL_Void = { _, _ in
            throw FileHelperError.generalError(33, "File helper error")
        }

        assertError(try manager.writeDocument(fileName: document.name + ".sig", data: dataToSave!),
                    throws: DocumentManagerError.general("33: \(String(describing: Optional("File helper error")))"))
    }
}
