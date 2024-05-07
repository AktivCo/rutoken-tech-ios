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
        documentData = "document to encrypt data".data(using: .utf8)
        token = TokenMock(serial: "87654321", currentInterface: .usb, supportedInterfaces: [.usb])
        pkcs11Helper.tokenPublisher.send([token])
    }

    func testEncryptCmsSuccessFile() throws {
        let certUrl = Bundle.getUrl(for: RtFile.bankCert.rawValue, in: RtFile.subdir)
        let certData = "bankCertData".data(using: .utf8)!
        let encryptedData = "encryptedData".data(using: .utf8)!
        fileHelper.readFileCallback = {
            XCTAssertEqual(certUrl, $0)
            return certData
        }
        openSslHelper.encryptCmsCallback = {
            XCTAssertEqual($1, certData)
            return encryptedData
        }
        let result = try manager.encryptDocument(document: documentData, with: .file(.bankCert))
        XCTAssertEqual(result, encryptedData)
    }

    func testEncryptCmsReadFileError() throws {
        let certUrl = Bundle.getUrl(for: RtFile.bankCert.rawValue, in: RtFile.subdir)
        let error = FileHelperError.generalError(23, "reading file error")
        fileHelper.readFileCallback = {
            XCTAssertEqual(certUrl, $0)
            throw error
        }
        assertError(try manager.encryptDocument(document: documentData, with: .file(.bankCert)), throws: error)
    }

    func testEncryptCmsSuccessToken() async throws {
        let encryptedData = "encryptedData".data(using: .utf8)!
        let certBodyData = "certBodyData".data(using: .utf8)!
        token.enumerateCertsCallback = {
            XCTAssertEqual($0, self.certId)
            return [Pkcs11ObjectMock(id: self.certId, body: certBodyData)]
        }
        openSslHelper.encryptCmsCallback = {
            XCTAssertEqual($1, certBodyData)
            return encryptedData
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            let result = (try manager.encryptDocument(document: documentData, with: .token(certId)))
            XCTAssertEqual(result, encryptedData)
        }
    }

    func testEncryptCmsTokenNotFoundError() async throws {
        assertError(try manager.encryptDocument(document: documentData, with: .token(certId)), throws: CryptoManagerError.tokenNotFound)
    }

    func testEncryptCmsNoSuitCertErrorToken() async throws {
        token.enumerateCertsCallback = {
            XCTAssertEqual($0, self.certId)
            return []
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            assertError(try manager.encryptDocument(document: documentData, with: .token(certId)), throws: CryptoManagerError.noSuitCert)
        }
    }

    func testEncryptCmsOpenSslErrorToken() async throws {
        let error = OpenSslError.generalError(23, "qwerty")
        token.enumerateCertsCallback = {
            XCTAssertEqual($0, self.certId)
            return [Pkcs11ObjectMock(id: self.certId, body: Data(repeating: 0x07, count: 10))]
        }
        openSslHelper.encryptCmsCallback = { _, _ in throw error }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            assertError(try manager.encryptDocument(document: documentData, with: .token(certId)), throws: error)
        }
    }
}
