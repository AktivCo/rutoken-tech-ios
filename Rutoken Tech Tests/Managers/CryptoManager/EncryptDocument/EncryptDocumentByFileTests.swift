//
//  EncryptDocumentByFileTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 07.05.2024.
//

import Combine
import XCTest

@testable import Rutoken_Tech


class EncryptDocumentByFileTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: RtMockPkcs11HelperProtocol!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!

    var documentData: Data!
    var certData: Data!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        pkcs11Helper = RtMockPkcs11HelperProtocol()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()

        pkcs11Helper.mocked_tokens = Just([]).eraseToAnyPublisher()
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)

        certData = Data("bankCertData".utf8)
        documentData = Data("document to encrypt data".utf8)
    }

    func testEncryptDocumentFileSuccess() throws {
        let certData = Data("bankCertData".utf8)
        let encryptedData = Data("encryptedData".utf8)
        let certUrl = URL(fileURLWithPath: RtFile.bankCert.rawValue)
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { file, dir in
            XCTAssertEqual(file, RtFile.bankCert.rawValue)
            XCTAssertEqual(dir, .credentials)
            return certUrl
        }
        fileHelper.mocked_readFile_fromUrlURL_Data = { url in
            XCTAssertEqual(url, certUrl)
            return certData
        }

        openSslHelper.encryptCmsCallback = {
            XCTAssertEqual($1, certData)
            return encryptedData
        }
        let result = try manager.encryptDocument(documentData, certFile: .bankCert)
        XCTAssertEqual(result, encryptedData)
    }

    func testEncryptDocumentFileGetUrlError() async {
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in nil }
        assertError(try manager.encryptDocument(documentData, certFile: .bankCert), throws: CryptoManagerError.unknown)
    }

    func testEncryptDocumentFileReadFileError() throws {
        let error = FileHelperError.generalError(23, "reading file error")
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in
            throw error
        }
        assertError(try manager.encryptDocument(documentData, certFile: .bankCert), throws: error)
    }

    func testEncryptDocumentFileOpenSslError() throws {
        let error = OpenSslError.generalError(32, "openssl error")
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in
            return self.certData
        }
        openSslHelper.encryptCmsCallback = { [self] in
            XCTAssertEqual(documentData, $0)
            XCTAssertEqual(certData, $1)
            throw error
        }
        assertError(try manager.encryptDocument(documentData, certFile: .bankCert), throws: error)
    }
}
