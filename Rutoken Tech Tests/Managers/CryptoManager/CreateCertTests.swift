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
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: FileSourceMock!
    var token: TokenMock!

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

        token = TokenMock(serial: "87654321", currentInterface: .usb)
        token.enumerateKeysWithAlgoCallback = { _ in
            return [Pkcs11KeyPair(publicKey: Pkcs11ObjectMock(),
                                  privateKey: Pkcs11ObjectMock())]
        }
        pkcs11Helper.tokenPublisher.send([token])
    }

    func testCreateCertSuccess() async throws {
        let getUrlExp = XCTestExpectation(description: "Get URL expectation")
        getUrlExp.expectedFulfillmentCount = 2
        fileSource.getUrlResult = { file, dir in
            defer { getUrlExp.fulfill() }
            XCTAssertTrue([RtFile.caKey, RtFile.caCert].map { $0.rawValue }.contains(file))
            XCTAssertEqual(dir, .credentials)
            return URL(fileURLWithPath: file)
        }
        let readFileExp = XCTestExpectation(description: "Read file expectation")
        readFileExp.expectedFulfillmentCount = 2
        fileHelper.mocked_readFile = { url in
            defer { readFileExp.fulfill() }
            XCTAssertTrue([RtFile.caKey, RtFile.caCert].map { URL(fileURLWithPath: $0.rawValue) }.contains(url))
            return Data()
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertNoThrowAsync(try await manager.createCert(for: "001",
                                                                  with: CsrModel.makeDefaultModel()))
        }
        await fulfillment(of: [getUrlExp, readFileExp], timeout: 0.3)
    }

    func testCreateCertTokenNotFoundError() async {
        await assertErrorAsync(
            try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
            throws: CryptoManagerError.tokenNotFound)
    }

    func testCreateCertGetUrlError() async throws {
        fileSource.getUrlResult = { _, _ in nil }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: CryptoManagerError.unknown)
        }
    }

    func testCreateCertWrappedKeyError() async throws {
        token.getWrappedKeyCallback = { _ in
            throw Pkcs11Error.internalError()
        }
        fileHelper.mocked_readFile = { _ in Data() }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: Pkcs11Error.internalError())
        }
    }

    func testCreateCertPrivateKeyUsagePeriodGetValueError() async throws {
        token.enumerateKeyWithIdCallback = { _ in
            var object = Pkcs11ObjectMock()
            object.setValue(forAttr: .startDate, value: .failure(Pkcs11Error.internalError()))
            return Pkcs11KeyPair(publicKey: object, privateKey: object)
        }
        fileHelper.mocked_readFile = { _ in Data() }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: Pkcs11Error.internalError())
        }
    }

    func testCreateCertReadFileFromBundleError() async throws {
        fileHelper.mocked_readFile = { _ in throw DocumentManagerError.general("") }

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
        fileHelper.mocked_readFile = { _ in Data() }

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
        fileHelper.mocked_readFile = { _ in Data() }

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
        fileHelper.mocked_readFile = { _ in Data() }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: CryptoManagerError.unknown)
        }
    }

    func testCreateCertConnectionLostError() async throws {
        token.importCertCallback = { _, _ in
            throw Pkcs11Error.internalError(rv: 10)
        }
        fileHelper.mocked_readFile = { _ in Data() }

        pkcs11Helper.isPresentCallback = { _ in
            return false
        }
        fileHelper.mocked_readFile = { _ in Data() }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel())
            },
            throws: CryptoManagerError.connectionLost)
    }
}
