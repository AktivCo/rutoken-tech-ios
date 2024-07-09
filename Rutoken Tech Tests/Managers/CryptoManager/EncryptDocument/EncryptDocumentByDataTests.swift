//
//  EncryptDocumentByDataTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 25.06.2024.
//

import XCTest

@testable import Rutoken_Tech


class EncryptDocumentByDataTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: FileSourceMock!

    var documentData: Data!
    var certData: Data!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = FileSourceMock()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)

        documentData = Data("document to encrypt data".utf8)
        certData = Data("bankCertData".utf8)
    }

    func testEncryptCmsDataSuccess() throws {
        let certData = Data("bankCertData".utf8)
        let encryptedData = Data("encryptedData".utf8)
        openSslHelper.encryptCmsCallback = {
            XCTAssertEqual($1, certData)
            return encryptedData
        }
        let result = try manager.encryptDocument(documentData, certData: certData)
        XCTAssertEqual(result, encryptedData)
    }

    func testEncryptCmsDataOpenSslError() throws {
        let error = OpenSslError.generalError(32, "openssl error")
        openSslHelper.encryptCmsCallback = { [self] in
            XCTAssertEqual(documentData, $0)
            XCTAssertEqual(certData, $1)
            throw error
        }
        assertError(try manager.encryptDocument(documentData, certData: certData), throws: error)
    }
}
