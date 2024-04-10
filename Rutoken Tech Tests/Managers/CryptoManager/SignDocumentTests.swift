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
    var certModel: CertModel!
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

        certModel = CertModel(keyId: "123",
                              hash: "hash",
                              tokenSerial: token.serial,
                              name: "Иванов Михаил Романович",
                              jobTitle: "Дизайнер",
                              companyName: "Рутокен",
                              keyAlgo: .gostR3410_2012_256,
                              expiryDate: "07.03.2024",
                              causeOfInvalid: nil)
        dataToSign = "Data to sign".data(using: .utf8)!
    }

    func testSignDocumentSuccess() async throws {
        let signed = "12345678qwerty"
        openSslHelper.signCmsCallback = {
            signed
        }
        token.enumerateCertsCallback = {
            XCTAssertEqual($0, self.certModel.keyId)
            return [Pkcs11ObjectMock(id: self.certModel.keyId, body: Data(repeating: 0x07, count: 10))]
        }
        token.getWrappedKeyCallback = {
            XCTAssertEqual($0, self.certModel.keyId)
            return WrappedPointer({
                OpaquePointer.init(bitPattern: 1)!
            }, {_ in})!
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            let result = try manager.signDocument(document: dataToSign, with: certModel.keyId!)
            XCTAssertEqual(signed, result)
        }
    }

    func testSignDocumentNoSuitCertError() async throws {
        token.enumerateCertsCallback = {
            XCTAssertEqual($0, self.certModel.keyId)
            return []
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(document: dataToSign, with: certModel.keyId!), throws: CryptoManagerError.noSuitCert)
        }
    }

    func testSignDocumentTokenNotFoundError() throws {
        assertError(try manager.signDocument(document: dataToSign, with: certModel.keyId!), throws: CryptoManagerError.tokenNotFound)
    }

    func testSignDocumentOpenSslError() async throws {
        let error = OpenSslError.generalError(100, "error")
        openSslHelper.signCmsCallback = {
            throw error
        }
        token.enumerateCertsCallback = {
            XCTAssertEqual($0, self.certModel.keyId)
            return [Pkcs11ObjectMock(id: self.certModel.keyId, body: Data(repeating: 0x07, count: 10))]
        }
        token.getWrappedKeyCallback = {
            XCTAssertEqual($0, self.certModel.keyId)
            return WrappedPointer({
                OpaquePointer.init(bitPattern: 1)!
            }, {_ in})!
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(document: dataToSign, with: certModel.keyId!), throws: error)
        }
    }

    func testSignDocumentTokenError() async throws {
        let error = TokenError.generalError
        token.getWrappedKeyCallback = {
            XCTAssertEqual($0, self.certModel.keyId)
            throw error
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(document: dataToSign, with: certModel.keyId!), throws: error)
        }
    }
}
