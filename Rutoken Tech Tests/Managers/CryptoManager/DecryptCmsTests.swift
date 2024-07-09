//
//  DecryptCmsTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 20.05.2024.
//

import XCTest

@testable import Rutoken_Tech


class CryptoManagerDecryptCmsTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: FileSourceMock!

    var token: TokenMock!
    var documentData: Data!
    var decryptedData: Data!
    var certId: String!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = FileSourceMock()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)

        certId = "certId"
        documentData = Data("data to decrypt".utf8)
        decryptedData = Data("decrypted data".utf8)
        token = TokenMock(serial: "87654321", currentInterface: .usb, supportedInterfaces: [.usb])
        pkcs11Helper.tokenPublisher.send([token])
    }

    func testDecryptCmsSuccess() async throws {
        openSslHelper.decryptCmsCallback = { data, _ in
            XCTAssertEqual(data, self.documentData)
            return self.decryptedData
        }
        token.getWrappedKeyCallback = {
            XCTAssertEqual($0, self.certId)
            return WrappedPointer<OpaquePointer>({
                OpaquePointer.init(bitPattern: 1)!
            }, { _ in})!
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            let result = try manager.decryptCms(encryptedData: documentData, with: certId)
            XCTAssertEqual(result, decryptedData)
        }
    }

    func testDecryptCmsTokenNotFoundError() async throws {
        assertError(try manager.decryptCms(encryptedData: documentData, with: certId), throws: CryptoManagerError.tokenNotFound)
    }

    func testDecryptCmsConnectionLostError() async throws {
        token.getWrappedKeyCallback = { _ in
            throw Pkcs11Error.internalError()
        }
        pkcs11Helper.isPresentCallback = { _ in
            return false
        }
        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
                _ = try manager.decryptCms(encryptedData: documentData, with: certId)
            },
            throws: CryptoManagerError.connectionLost)
    }

    func testDecryptCmsKeyNotFoundError() async throws {
        token.getWrappedKeyCallback = { _ in
            throw Pkcs11Error.internalError()
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            assertError(try manager.decryptCms(encryptedData: documentData, with: certId), throws: Pkcs11Error.internalError())
        }
    }

    func testDecryptCmsOpenSslError() async throws {
        let error = OpenSslError.generalError(32, nil)
        openSslHelper.decryptCmsCallback = { _, _ in
            throw error
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            assertError(try manager.decryptCms(encryptedData: documentData, with: certId), throws: error)
        }
    }
}
