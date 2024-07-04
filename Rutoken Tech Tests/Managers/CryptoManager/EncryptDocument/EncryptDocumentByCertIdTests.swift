//
//  EncryptDocumentByCertIdTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 25.06.2024.
//

import XCTest

@testable import Rutoken_Tech


class EncryptDocumentByCertIdTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: FileHelperMock!
    var fileSource: FileSourceMock!

    var token: TokenMock!
    var documentData: Data!
    var certId: String!

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

        certId = "certId"
        documentData = Data("document to encrypt data".utf8)
        token = TokenMock(serial: "87654321", currentInterface: .usb, supportedInterfaces: [.usb])
        pkcs11Helper.tokenPublisher.send([token])
    }

    func testEncryptDocumentTokenSuccess() async throws {
        let encryptedData = Data("encryptedData".utf8)
        let certBodyData = Data("certBodyData".utf8)

        token.enumerateCertsWithIdCallback = {
            XCTAssertEqual($0, self.certId)
            var object = Pkcs11ObjectMock()
            object.setValue(forAttr: .value, value: .success(certBodyData))
            return [object]
        }
        openSslHelper.encryptCmsCallback = {
            XCTAssertEqual($1, certBodyData)
            return encryptedData
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            let result = (try manager.encryptDocument(documentData, certId: certId))
            XCTAssertEqual(result, encryptedData)
        }
    }

    func testEncryptDocumentTokenNotFoundError() async throws {
        assertError(try manager.encryptDocument(documentData, certId: certId), throws: CryptoManagerError.tokenNotFound)
    }

    func testEncryptDocumentConnectionLostError() async throws {
        token.enumerateCertsWithIdCallback = { _ in
            throw Pkcs11Error.internalError()
        }
        pkcs11Helper.isPresentCallback = { _ in
            return false
        }
        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
                _ = try manager.encryptDocument(documentData, certId: certId)
            },
            throws: CryptoManagerError.connectionLost)
    }


    func testEncryptDocumentTokenNoSuitCertError() async throws {
        token.enumerateCertsWithIdCallback = {
            XCTAssertEqual($0, self.certId)
            return []
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            assertError(try manager.encryptDocument(documentData, certId: certId), throws: CryptoManagerError.noSuitCert)
        }
    }

    func testEncryptDocumentTokenOpenSslError() async throws {
        let error = OpenSslError.generalError(23, "qwerty")
        token.enumerateCertsWithIdCallback = {
            XCTAssertEqual($0, self.certId)
            return [Pkcs11ObjectMock()]
        }
        openSslHelper.encryptCmsCallback = { _, _ in throw error }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            assertError(try manager.encryptDocument(documentData, certId: certId), throws: error)
        }
    }
}
