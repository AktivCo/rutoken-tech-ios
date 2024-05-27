//
//  CreateCertTests.swift
//  Rutoken Tech Tests
//
//  Created by Ivan Poderegin on 16.01.2024.
//

import XCTest

@testable import Rutoken_Tech


final class CryptoManagerCreateCertTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: FileHelperMock!
    var token: TokenMock!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = FileHelperMock()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper, openSslHelper: openSslHelper, fileHelper: fileHelper)

        token = TokenMock(serial: "87654321", currentInterface: .usb)
        token.enumerateKeysCallback = { _, _ in
            return [Pkcs11KeyPair(publicKey: Pkcs11ObjectMock(),
                                  privateKey: Pkcs11ObjectMock())]
        }
        pkcs11Helper.tokenPublisher.send([token])
    }

    func testCreateCertSuccess() async throws {
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertNoThrowAsync(try await manager.createCert(for: "001",
                                                                  with: CsrModel.makeDefaultModel()))
        }
    }

    func testCreateCertTokenNotFoundError() async {
        await assertErrorAsync(
            try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
            throws: CryptoManagerError.tokenNotFound)
    }

    func testCreateCertWrappedKeyError() async throws {
        token.getWrappedKeyCallback = { _ in
            throw TokenError.keyNotFound
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: TokenError.keyNotFound)
        }
    }

    func testCreateCertPrivateKeyUsagePeriodGetValueError() async throws {
        token.enumerateKeysCallback = { _, _ in
            var object = Pkcs11ObjectMock()
            object.setValue(forAttr: .startDate, value: .failure(TokenError.generalError))
            return [Pkcs11KeyPair(publicKey: object, privateKey: object)]
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: TokenError.generalError)
        }
    }

    func testCreateCertReadFileFromBundleError() async throws {
        fileHelper.readFileCallback = { _ in throw DocumentManagerError.general("") }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: DocumentManagerError.general(""))
        }
    }

    func testCreateCertCreateCsrError() async throws {
        openSslHelper.createCsrCallback = { _, _ in
            throw CryptoManagerError.unknown
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: CryptoManagerError.unknown)
        }
    }

    func testCreateCertCreateCertError() async throws {
        openSslHelper.createCertCallback = {
            throw CryptoManagerError.unknown
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: CryptoManagerError.unknown)
        }
    }

    func testCreateCertImportCertError() async throws {
        token.importCertCallback = { _, _ in
            throw CryptoManagerError.unknown
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: CryptoManagerError.unknown)
        }
    }

    func testCreateCertTokenDisconnectedError() async throws {
        token.importCertCallback = { _, _ in
            throw TokenError.tokenDisconnected
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: TokenError.tokenDisconnected)
        }
    }
}
