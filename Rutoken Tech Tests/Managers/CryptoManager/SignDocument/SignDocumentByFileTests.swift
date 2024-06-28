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
    var fileSource: FileSourceMock!

    var dataToSign: Data!
    var signed: String!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = FileHelperMock()
        fileSource = FileSourceMock()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)

        dataToSign = Data("Data to sign".utf8)
        signed = "12345678qwerty"
    }

    func testSignDocumentFileSuccess() async throws {
        let getUrlExp = XCTestExpectation(description: "Get URL expectation")
        getUrlExp.expectedFulfillmentCount = 3

        fileSource.getUrlResult = { file, dir in
            defer { getUrlExp.fulfill() }
            XCTAssertEqual(dir, .credentials)
            XCTAssertTrue([RtFile.rootCaKey, .rootCaCert, .caCert].map { $0.rawValue }.contains(file))
            return URL(fileURLWithPath: "")
        }

        openSslHelper.signDocumentCallback = {
            self.signed
        }
        let result = try manager.signDocument(dataToSign, keyFile: .rootCaKey, certFile: .rootCaCert)
        XCTAssertEqual(signed, result)
        await fulfillment(of: [getUrlExp], timeout: 0.3)
    }

    func testSignDocumentGetUrlError() async throws {
        fileSource.getUrlResult = { _, _ in nil }
        assertError(try manager.signDocument(dataToSign, keyFile: .rootCaKey, certFile: .rootCaCert), throws: CryptoManagerError.unknown)
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
