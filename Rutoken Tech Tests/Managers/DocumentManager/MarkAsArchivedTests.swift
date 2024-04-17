//
//  MarkAsArchivedTests.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 22.04.2024.
//

import PDFKit
import XCTest

@testable import Rutoken_Tech


class DocumentManagerMarkAsArchivedTests: XCTestCase {
    var manager: DocumentManager!
    var helper: FileHelperMock!
    var dataToSave: Data!
    var document: BankDocument!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        helper = FileHelperMock()
        helper.readFileCallback = { _ in "[]".data(using: .utf8)! }
        manager = DocumentManager(helper: helper)
    }

    func testMarkAsArchivedSuccess() throws {
        document = BankDocument(name: "Платежное \"поручение\" №121",
                                action: .sign,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentDay: Date())
        helper.readFileCallback = { _ in return try BankDocument.jsonEncoder.encode([self.document]) }

        manager = DocumentManager(helper: helper)

        let docs = try awaitPublisherUnwrapped(manager.documents.dropFirst()) {
            try manager.markAsArchived(documentName: document.name)
        }

        XCTAssertTrue(docs.first!.inArchive)
    }

    func testMarkAsArchivedNoDocument() throws {
        try awaitPublisher(manager.documents.dropFirst(), isInverted: true)
        XCTAssertThrowsError(try manager.markAsArchived(documentName: "some name")) {
            XCTAssertEqual($0 as? DocumentManagerError, DocumentManagerError.general("Something went wrong during reading the file"))
        }
    }
}
