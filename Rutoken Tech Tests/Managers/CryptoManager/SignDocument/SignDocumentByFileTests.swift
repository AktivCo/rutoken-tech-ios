//
//  SignDocumentByFileTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 25.06.2024.
//

import XCTest

@testable import Rutoken_Tech


class SignDocumentByFileTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: FileHelperMock!

    var dataToSign: Data!
    var signed: String!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = FileHelperMock()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper)

        dataToSign = Data("Data to sign".utf8)
        signed = "12345678qwerty"
    }

    func testSignDocumentFileSuccess() async throws {
        openSslHelper.signDocumentCallback = {
            self.signed
        }
        let result = try manager.signDocument(dataToSign, keyFile: .rootCaKey, certFile: .rootCaCert)
        XCTAssertEqual(signed, result)
    }

    func testSignDocumentFileHelperError() async throws {
        let error = FileHelperError.generalError(100, "error")
        fileHelper.readFileCallback = { _ in
            throw error
        }
        assertError(try manager.signDocument(dataToSign, keyFile: .rootCaKey, certFile: .rootCaCert), throws: error)
    }

    func testSignDocumentFileOpenSslError() async throws {
        let error = OpenSslError.generalError(100, "error")
        openSslHelper.signDocumentCallback = {
            throw error
        }
        assertError(try manager.signDocument(dataToSign, keyFile: .rootCaKey, certFile: .rootCaCert), throws: error)
    }
}
