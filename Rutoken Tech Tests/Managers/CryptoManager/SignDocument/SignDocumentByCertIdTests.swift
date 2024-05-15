//
//  SignDocumentByCertIdTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 10.04.2024.
//

import XCTest

@testable import Rutoken_Tech


class SignDocumentByCertIdTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: FileHelperMock!

    var token: TokenMock!
    var keyId: String!
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

        token = TokenMock(serial: "87654321", currentInterface: .usb, supportedInterfaces: [.usb])
        pkcs11Helper.tokenPublisher.send([token])

        keyId = "123"

        dataToSign = Data("Data to sign".utf8)
        signed = "12345678qwerty"
    }

    func testSignDocumentTokenSuccess() async throws {
        openSslHelper.signDocumentCallback = {
            self.signed
        }
        token.enumerateCertsWithIdCallback = {
            XCTAssertEqual($0, self.keyId)
            return [Pkcs11ObjectMock()]
        }
        token.getWrappedKeyCallback = {
            XCTAssertEqual($0, self.keyId)
            return WrappedPointer<OpaquePointer>({
                OpaquePointer.init(bitPattern: 1)!
            }, {_ in})!
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            let result = try manager.signDocument(dataToSign, certId: keyId)
            XCTAssertEqual(signed, result)
        }
    }

    func testSignDocumentTokenNotFoundError() throws {
        assertError(try manager.signDocument(dataToSign, certId: keyId), throws: CryptoManagerError.tokenNotFound)
    }

    func testSignDocumentTokenError() async throws {
        let error = Pkcs11Error.internalError()
        token.getWrappedKeyCallback = {
            XCTAssertEqual($0, self.keyId)
            throw error
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(dataToSign, certId: keyId), throws: error)
        }
    }

    func testSignDocumentNoSuitCertError() async throws {
        token.enumerateCertsWithIdCallback = {
            XCTAssertEqual($0, self.keyId)
            return []
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(dataToSign, certId: keyId), throws: CryptoManagerError.noSuitCert)
        }
    }

    func testSignDocumentFileHelperError() async throws {
        let error = FileHelperError.generalError(32, "FileHelper error")
        token.enumerateCertsWithIdCallback = {
            XCTAssertEqual($0, self.keyId)
            return [Pkcs11ObjectMock()]
        }
        fileHelper.readFileCallback = { _ in
            throw error
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(dataToSign, certId: keyId), throws: error)
        }
    }

    func testSignDocumentTokenOpenSslError() async throws {
        let error = OpenSslError.generalError(100, "error")
        openSslHelper.signDocumentCallback = {
            throw error
        }
        token.enumerateCertsWithIdCallback = {
            XCTAssertEqual($0, self.keyId)
            return [Pkcs11ObjectMock()]
        }
        token.getWrappedKeyCallback = {
            XCTAssertEqual($0, self.keyId)
            return WrappedPointer<OpaquePointer>({
                OpaquePointer.init(bitPattern: 1)!
            }, {_ in})!
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(dataToSign, certId: self.keyId), throws: error)
        }
    }
}
