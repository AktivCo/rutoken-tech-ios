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
    }

    func testMarkAsArchivedSuccess() throws {
        document = BankDocument(name: "Платежное \"поручение\" №121",
                                action: .sign,
                                amount: 35600,
                                companyName: "ОАО \"Нефтегаз\"",
                                paymentTime: Date())
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        helper.mocked_readFile_fromUrlURL_Data = { _ in return try BankDocument.jsonEncoder.encode([self.document]) }
        helper.mocked_clearDir_dirUrlURL_Void = { _ in }
        try manager.reset()

        let docs = try awaitPublisherUnwrapped(manager.documents.dropFirst()) {
            try manager.markAsArchived(documentName: document.name)
        }
        XCTAssertTrue(docs.first!.inArchive)
    }

    func testMarkAsArchivedNoDocument() throws {
        source.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        helper.mocked_readFile_fromUrlURL_Data = { _ in Data("[]".utf8) }
        helper.mocked_clearDir_dirUrlURL_Void = { _ in }
        try manager.reset()
        try awaitPublisher(manager.documents.dropFirst(), isInverted: true)
        XCTAssertThrowsError(try manager.markAsArchived(documentName: "some name")) {
            XCTAssertEqual($0 as? DocumentManagerError, DocumentManagerError.general("Something went wrong during reading the file"))
        }
    }
}
