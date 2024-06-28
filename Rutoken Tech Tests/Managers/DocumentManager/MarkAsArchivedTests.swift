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
    var source: FileSourceMock!

    var dataToSave: Data!
    var document: BankDocument!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        helper = FileHelperMock()
        source = FileSourceMock()
        manager = DocumentManager(helper: helper, fileSource: source)
    }

    func testMarkAsArchivedSuccess() throws {
        document = BankDocument(name: "Платежное \"поручение\" №121",
                                action: .sign,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentTime: Date())
        helper.readFileCallback = { _ in return try BankDocument.jsonEncoder.encode([self.document]) }
        try manager.reset()

        let docs = try awaitPublisherUnwrapped(manager.documents.dropFirst()) {
            try manager.markAsArchived(documentName: document.name)
        }
        XCTAssertTrue(docs.first!.inArchive)
    }

    func testMarkAsArchivedNoDocument() throws {
        helper.readFileCallback = { _ in Data("[]".utf8) }
        try manager.reset()
        try awaitPublisher(manager.documents.dropFirst(), isInverted: true)
        XCTAssertThrowsError(try manager.markAsArchived(documentName: "some name")) {
            XCTAssertEqual($0 as? DocumentManagerError, DocumentManagerError.general("Something went wrong during reading the file"))
        }
    }
}
