//
//  EncryptDocumentTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 07.05.2024.
//

import XCTest

@testable import Rutoken_Tech


class CryptoManagerEncryptDocumentTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: FileHelperMock!

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
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper)

        certId = "certId"
        documentData = Data("document to encrypt data".utf8)
        token = TokenMock(serial: "87654321", currentInterface: .usb, supportedInterfaces: [.usb])
        pkcs11Helper.tokenPublisher.send([token])
    }

    func testEncryptCmsFileSuccess() throws {
        let certUrl = Bundle.getUrl(for: RtFile.bankCert.rawValue, in: RtFile.subdir)
        let certData = Data("bankCertData".utf8)
        let encryptedData = Data("encryptedData".utf8)
        fileHelper.readFileCallback = {
            XCTAssertEqual(certUrl, $0)
            return certData
        }
        openSslHelper.encryptCmsCallback = {
            XCTAssertEqual($1, certData)
            return encryptedData
        }
        let result = try manager.encryptDocument(documentData, certFile: .bankCert)
        XCTAssertEqual(result, encryptedData)
    }

    func testEncryptCmsReadFileError() throws {
        let certUrl = Bundle.getUrl(for: RtFile.bankCert.rawValue, in: RtFile.subdir)
        let error = FileHelperError.generalError(23, "reading file error")
        fileHelper.readFileCallback = {
            XCTAssertEqual(certUrl, $0)
            throw error
        }
        assertError(try manager.encryptDocument(documentData, certFile: .bankCert), throws: error)
    }

    func testEncryptCmsTokenSuccess() async throws {
        let encryptedData = Data("encryptedData".utf8)
        let certBodyData = Data("certBodyData".utf8)

        token.enumerateCertsCallback = {
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

    func testEncryptCmsTokenNotFoundError() async throws {
        assertError(try manager.encryptDocument(documentData, certId: certId), throws: CryptoManagerError.tokenNotFound)
    }

    func testEncryptCmsTokenNoSuitCertError() async throws {
        token.enumerateCertsCallback = {
            XCTAssertEqual($0, self.certId)
            return []
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            assertError(try manager.encryptDocument(documentData, certId: certId), throws: CryptoManagerError.noSuitCert)
        }
    }

    func testEncryptCmsTokenOpenSslError() async throws {
        let error = OpenSslError.generalError(23, "qwerty")
        token.enumerateCertsCallback = {
            XCTAssertEqual($0, self.certId)
            return [Pkcs11ObjectMock()]
        }
        openSslHelper.encryptCmsCallback = { _, _ in throw error }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            assertError(try manager.encryptDocument(documentData, certId: certId), throws: error)
        }
    }
}
