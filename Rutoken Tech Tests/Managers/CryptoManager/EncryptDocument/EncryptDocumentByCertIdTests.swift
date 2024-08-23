//
//  EncryptDocumentByCertIdTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 25.06.2024.
//

import Combine
import XCTest

@testable import Rutoken_Tech


class EncryptDocumentByCertIdTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: RtMockPkcs11HelperProtocol!
    var pcscHelper: RtMockPcscHelperProtocol!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!

    var token: TokenMock!
    var tokensPublisher: CurrentValueSubject<[Pkcs11TokenProtocol], Never>!
    var documentData: Data!
    var certId: String!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        pkcs11Helper = RtMockPkcs11HelperProtocol()
        pcscHelper = RtMockPcscHelperProtocol()
        openSslHelper = OpenSslHelperMock()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()

        token = TokenMock(serial: "87654321", currentInterface: .usb, supportedInterfaces: [.usb])
        tokensPublisher = CurrentValueSubject<[Pkcs11TokenProtocol], Never>([token])
        pkcs11Helper.mocked_tokens = tokensPublisher.eraseToAnyPublisher()
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)

        certId = "certId"
        documentData = Data("document to encrypt data".utf8)
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
        pkcs11Helper.mocked_isPresent__SlotCK_SLOT_ID_Bool = { _ in
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
