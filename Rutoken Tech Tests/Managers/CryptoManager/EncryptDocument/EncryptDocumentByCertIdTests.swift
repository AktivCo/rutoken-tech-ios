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
    var openSslHelper: RtMockOpenSslHelperProtocol!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!

    var token: RtMockPkcs11TokenProtocol!
    var tokensPublisher: CurrentValueSubject<[Pkcs11TokenProtocol], Never>!
    var documentData: Data!
    var certId: Data!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        pkcs11Helper = RtMockPkcs11HelperProtocol()
        pcscHelper = RtMockPcscHelperProtocol()
        openSslHelper = RtMockOpenSslHelperProtocol()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()

        token = RtMockPkcs11TokenProtocol()
        token.setup()
        tokensPublisher = CurrentValueSubject<[Pkcs11TokenProtocol], Never>([token])
        pkcs11Helper.mocked_tokens = tokensPublisher.eraseToAnyPublisher()
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)

        certId = Data.random()
        documentData = Data("document to encrypt data".utf8)
    }

    func testEncryptDocumentTokenSuccess() async throws {
        let encryptedData = Data("encryptedData".utf8)
        let certBodyData = Data("certBodyData".utf8)

        token.mocked_enumerateCerts_byIdData_ArrayOf_Pkcs11ObjectProtocol = { id in
            XCTAssertEqual(id, self.certId)
            let object = RtMockPkcs11ObjectProtocol()
            object.mocked_getValue_forAttrAttrtypePkcs11DataAttribute_Data = { attr in
                XCTAssertEqual(attr, .value)
                return certBodyData
            }
            return [object]
        }

        openSslHelper.mocked_encryptDocument_forContentData_withCertData_Data = { content, cert in
            XCTAssertEqual(content, self.documentData)
            XCTAssertEqual(cert, certBodyData)
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
        token.mocked_enumerateCerts_byIdData_ArrayOf_Pkcs11ObjectProtocol = { _ in
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
        token.mocked_enumerateCerts_byIdData_ArrayOf_Pkcs11ObjectProtocol = { _ in
            return []
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            assertError(try manager.encryptDocument(documentData, certId: certId), throws: CryptoManagerError.noSuitCert)
        }
    }

    func testEncryptDocumentTokenOpenSslError() async throws {
        let error = OpenSslError.generalError(23, "qwerty")
        token.mocked_enumerateCerts_byIdData_ArrayOf_Pkcs11ObjectProtocol = { _ in
            let object = RtMockPkcs11ObjectProtocol()
            object.mocked_getValue_forAttrAttrtypePkcs11DataAttribute_Data = { _ in Data() }
            return [object]
        }
        openSslHelper.mocked_encryptDocument_forContentData_withCertData_Data = { _, _ in throw error }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            assertError(try manager.encryptDocument(documentData, certId: certId), throws: error)
        }
    }
}
