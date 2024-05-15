//
//  EncryptDocumentByFileTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 07.05.2024.
//

import XCTest

@testable import Rutoken_Tech


class EncryptDocumentByFileTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: FileHelperMock!

    var documentData: Data!
    var certData: Data!
    var certUrl: URL!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = FileHelperMock()
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper)

        certData = Data("bankCertData".utf8)
        documentData = Data("document to encrypt data".utf8)
        certUrl = Bundle.getUrl(for: RtFile.bankCert.rawValue, in: RtFile.subdir)
    }

    func testEncryptDocumentFileSuccess() throws {
        let certData = Data("bankCertData".utf8)
        let encryptedData = Data("encryptedData".utf8)
        fileHelper.readFileCallback = { [self] in
            XCTAssertEqual(certUrl, $0)
            return certData
        }
        openSslHelper.encryptCmsCallback = {
            XCTAssertEqual($1, certData)
            return encryptedData
        }
        let result = try manager.encryptDocument(documentData, certFile: .bankCert)
        XCTAssertEqual(result, encryptedData)
    }

    func testEncryptDocumentFileReadFileError() throws {
        let error = FileHelperError.generalError(23, "reading file error")
        fileHelper.readFileCallback = { [self] in
            XCTAssertEqual(certUrl, $0)
            throw error
        }
        assertError(try manager.encryptDocument(documentData, certFile: .bankCert), throws: error)
    }

    func testEncryptDocumentFileOpenSslError() throws {
        let error = OpenSslError.generalError(32, "openssl error")
        fileHelper.readFileCallback = { [self] in
            XCTAssertEqual(certUrl, $0)
            return certData
        }
        openSslHelper.encryptCmsCallback = { [self] in
            XCTAssertEqual(documentData, $0)
            XCTAssertEqual(certData, $1)
            throw error
        }
        assertError(try manager.encryptDocument(documentData, certFile: .bankCert), throws: error)
    }
}
