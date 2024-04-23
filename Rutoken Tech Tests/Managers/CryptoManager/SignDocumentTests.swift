//
//  SignDocumentTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 10.04.2024.
//

import XCTest

@testable import Rutoken_Tech


class CryptoManagerSignDocumentTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: FileHelperMock!

    var token: TokenMock!
    var keyId: String!
    var dataToSign: Data!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = FileHelperMock()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper)

        token = TokenMock(serial: "87654321", currentInterface: .usb, supportedInterfaces: [.usb])
        pkcs11Helper.tokenPublisher.send([token])

        keyId = "123"
        dataToSign = "Data to sign".data(using: .utf8)!
    }

    func testSignDocumentSuccess() async throws {
        let signed = "12345678qwerty"
        openSslHelper.signCmsCallback = {
            signed
        }
        token.enumerateCertsCallback = {
            XCTAssertEqual($0, self.keyId)
            return [Pkcs11ObjectMock(id: self.keyId, body: Data(repeating: 0x07, count: 10))]
        }
        token.getWrappedKeyCallback = {
            XCTAssertEqual($0, self.keyId)
            return WrappedPointer<OpaquePointer>({
                OpaquePointer.init(bitPattern: 1)!
            }, {_ in})!
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            let result = try manager.signDocument(document: dataToSign, with: self.keyId!)
            XCTAssertEqual(signed, result)
        }
    }

    func testSignDocumentNoSuitCertError() async throws {
        token.enumerateCertsCallback = {
            XCTAssertEqual($0, self.keyId)
            return []
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(document: dataToSign, with: keyId), throws: CryptoManagerError.noSuitCert)
        }
    }

    func testSignDocumentTokenNotFoundError() throws {
        assertError(try manager.signDocument(document: dataToSign, with: self.keyId), throws: CryptoManagerError.tokenNotFound)
    }

    func testSignDocumentOpenSslError() async throws {
        let error = OpenSslError.generalError(100, "error")
        openSslHelper.signCmsCallback = {
            throw error
        }
        token.enumerateCertsCallback = {
            XCTAssertEqual($0, self.keyId)
            return [Pkcs11ObjectMock(id: self.keyId, body: Data(repeating: 0x07, count: 10))]
        }
        token.getWrappedKeyCallback = {
            XCTAssertEqual($0, self.keyId)
            return WrappedPointer<OpaquePointer>({
                OpaquePointer.init(bitPattern: 1)!
            }, {_ in})!
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(document: dataToSign, with: self.keyId), throws: error)
        }
    }

    func testSignDocumentTokenError() async throws {
        let error = TokenError.generalError
        token.getWrappedKeyCallback = {
            XCTAssertEqual($0, self.keyId)
            throw error
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(document: dataToSign, with: self.keyId), throws: error)
        }
    }
}
