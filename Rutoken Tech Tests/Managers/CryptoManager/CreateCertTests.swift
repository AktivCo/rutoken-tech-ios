//
//  CreateCertTests.swift
//  Rutoken Tech Tests
//
//  Created by Ivan Poderegin on 16.01.2024.
//

import Combine
import XCTest

@testable import Rutoken_Tech


final class CryptoManagerCreateCertTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: RtMockPkcs11HelperProtocol!
    var pcscHelper: RtMockPcscHelperProtocol!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!
    var token: TokenMock!
    var tokensPublisher: CurrentValueSubject<[Pkcs11TokenProtocol], Never>!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = RtMockPkcs11HelperProtocol()
        pcscHelper = RtMockPcscHelperProtocol()
        openSslHelper = OpenSslHelperMock()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()

        token = TokenMock(serial: "87654321", currentInterface: .usb)
        token.enumerateKeysWithAlgoCallback = { _ in
            return [Pkcs11KeyPair(publicKey: Pkcs11ObjectMock(),
                                  privateKey: Pkcs11ObjectMock())]
        }

        tokensPublisher = CurrentValueSubject<[Pkcs11TokenProtocol], Never>([token])
        pkcs11Helper.mocked_tokens = tokensPublisher.eraseToAnyPublisher()
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)
    }

    func testCreateCertSuccess() async throws {
        let getUrlExp = XCTestExpectation(description: "Get URL expectation")
        getUrlExp.expectedFulfillmentCount = 2
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { file, dir in
            defer { getUrlExp.fulfill() }
            XCTAssertTrue([RtFile.caKey, RtFile.caCert].map { $0.rawValue }.contains(file))
            XCTAssertEqual(dir, .credentials)
            return URL(fileURLWithPath: file)
        }
        let readFileExp = XCTestExpectation(description: "Read file expectation")
        readFileExp.expectedFulfillmentCount = 2
        fileHelper.mocked_readFile_fromUrlURL_Data = { url in
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
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in nil }
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
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }

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
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: Pkcs11Error.internalError())
        }
    }

    func testCreateCertReadFileFromBundleError() async throws {
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in throw DocumentManagerError.general("") }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: DocumentManagerError.general(""))
        }
    }

    func testCreateCertCreateCsrError() async throws {
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in nil }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }
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
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }

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
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }

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
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }

        pkcs11Helper.mocked_isPresent__SlotCK_SLOT_ID_Bool = { _ in
            return false
        }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel())
            },
            throws: CryptoManagerError.connectionLost)
    }
}
