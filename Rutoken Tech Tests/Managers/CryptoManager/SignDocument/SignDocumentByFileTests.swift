//
//  SignDocumentByFileTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 25.06.2024.
//

import Combine
import XCTest

@testable import Rutoken_Tech


class SignDocumentByFileTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: RtMockPkcs11HelperProtocol!
    var pcscHelper: RtMockPcscHelperProtocol!
    var openSslHelper: RtMockOpenSslHelperProtocol!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!

    var dataToSign: Data!
    var signed: String!

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

        dataToSign = Data("Data to sign".utf8)
        signed = "12345678qwerty"
    }

    func testSignDocumentFileSuccess() async throws {
        let keyData = "key".data(using: .utf8)!
        let certData = "cert".data(using: .utf8)!
        let caCertData = "ca cert".data(using: .utf8)!
        var datas = [caCertData, certData, keyData]
        let getUrlExp = XCTestExpectation(description: "Get URL expectation")
        getUrlExp.expectedFulfillmentCount = 3

        let someUrl = URL(fileURLWithPath: "someUrl")
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { file, dir in
            defer { getUrlExp.fulfill() }
            XCTAssertEqual(dir, .credentials)
            XCTAssertTrue([RtFile.rootCaKey, .rootCaCert, .caCert].map { $0.rawValue }.contains(file))
            return someUrl
        }
        fileHelper.mocked_readFile_fromUrlURL_Data = { url in
            XCTAssertEqual(someUrl, url)
            return datas.popLast()!
        }

        openSslHelper.mocked_signDocument__DocumentData_keyData_certData_certChainArrayOf_Data_String = { content, key, cert, chain in
            XCTAssertEqual(content, self.dataToSign)
            XCTAssertEqual(key, keyData)
            XCTAssertEqual(cert, certData)
            XCTAssertEqual(chain, [caCertData])
            return self.signed
        }
        let result = try manager.signDocument(dataToSign, keyFile: .rootCaKey, certFile: .rootCaCert)
        XCTAssertEqual(signed, result)
        await fulfillment(of: [getUrlExp], timeout: 0.3)
    }

    func testSignDocumentGetUrlError() async throws {
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in nil }
        assertError(try manager.signDocument(dataToSign, keyFile: .rootCaKey, certFile: .rootCaCert), throws: CryptoManagerError.unknown)
    }

    func testSignDocumentFileHelperError() async throws {
        let error = FileHelperError.generalError(100, "error")
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in
            throw error
        }
        assertError(try manager.signDocument(dataToSign, keyFile: .rootCaKey, certFile: .rootCaCert), throws: error)
    }

    func testSignDocumentFileOpenSslError() async throws {
        let error = OpenSslError.generalError(100, "error")
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }
        openSslHelper.mocked_signDocument__DocumentData_keyData_certData_certChainArrayOf_Data_String = { _, _, _, _ in
            throw error
        }

        assertError(try manager.signDocument(dataToSign, keyFile: .rootCaKey, certFile: .rootCaCert), throws: error)
    }
}
