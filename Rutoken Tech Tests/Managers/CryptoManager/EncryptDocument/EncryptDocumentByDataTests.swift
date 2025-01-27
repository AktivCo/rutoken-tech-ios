//
//  EncryptDocumentByDataTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 25.06.2024.
//

import Combine
import XCTest

@testable import Rutoken_Tech


class EncryptDocumentByDataTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: RtMockPkcs11HelperProtocol!
    var pcscHelper: RtMockPcscHelperProtocol!
    var openSslHelper: RtMockOpenSslHelperProtocol!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!

    var documentData: Data!
    var certData: Data!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        pkcs11Helper = RtMockPkcs11HelperProtocol()
        pcscHelper = RtMockPcscHelperProtocol()
        openSslHelper = RtMockOpenSslHelperProtocol()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()

        pkcs11Helper.mocked_tokens = Just([]).eraseToAnyPublisher()
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)

        documentData = Data("document to encrypt data".utf8)
        certData = Data("bankCertData".utf8)
    }

    func testEncryptCmsDataSuccess() throws {
        let certData = Data("bankCertData".utf8)
        let encryptedData = Data("encryptedData".utf8)
        openSslHelper.mocked_encryptDocument_forContentData_withCertData_Data = { content, cert in
            XCTAssertEqual(content, self.documentData)
            XCTAssertEqual(cert, certData)
            return encryptedData
        }
        let result = try manager.encryptDocument(documentData, certData: certData)
        XCTAssertEqual(result, encryptedData)
    }

    func testEncryptCmsDataOpenSslError() throws {
        let error = OpenSslError.generalError(32, "openssl error")
        openSslHelper.mocked_encryptDocument_forContentData_withCertData_Data = { _, _ in throw error }
        assertError(try manager.encryptDocument(documentData, certData: certData), throws: error)
    }
}
