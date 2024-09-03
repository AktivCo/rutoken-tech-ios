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
    var openSslHelper: RtMockOpenSslHelperProtocol!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!
    var token: RtMockPkcs11TokenProtocol!
    var tokensPublisher: CurrentValueSubject<[Pkcs11TokenProtocol], Never>!

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
    }

    func testCreateCertSuccess() async throws {
        let csr = "some csr"
        let caKeyData = "key data".data(using: .utf8)!
        let caCertData = "cert data".data(using: .utf8)!
        var datas = [caCertData, caKeyData]
        let certRequest = CsrModel.makeDefaultModel()

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
            return datas.popLast()!
        }

        var privateKey = Pkcs11ObjectMock()
        let startData = "20230101".data(using: .utf8)!
        let endData = "20240101".data(using: .utf8)!
        privateKey.setValue(forAttr: .startDate, value: .success(startData))
        privateKey.setValue(forAttr: .endDate, value: .success(endData))
        let certInfo = CertInfo(startDate: startData.getDate(with: "YYYYMMdd"),
                                endDate: endData.getDate(with: "YYYYMMdd"))
        token.mocked_enumerateKey_byIdString_Pkcs11KeyPair = { _ in
            return Pkcs11KeyPair(publicKey: Pkcs11ObjectMock(),
                                 privateKey: privateKey)
        }
        openSslHelper.mocked_createCsr_withWrappedkeyWrappedPointerOf_OpaquePointer_forRequestCsrModel_withInfoCertInfo_String = { _, req, info in
            XCTAssertEqual(req, certRequest)
            XCTAssertEqual(info, certInfo)
            return csr
        }
        openSslHelper.mocked_createCert_forCsrString_withCakeyData_certCacertData_Data = { csrString, caKey, caCert in
            XCTAssertEqual(csr, csrString)
            XCTAssertEqual(caKey, caKeyData)
            XCTAssertEqual(caCert, caCertData)
            return Data()
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertNoThrowAsync(try await manager.createCert(for: "001",
                                                                  with: certRequest))
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
        token.mocked_getWrappedKey_withIdString_WrappedPointerOf_OpaquePointer = { _ in
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
        token.mocked_enumerateKey_byIdString_Pkcs11KeyPair = { _ in
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
        let error = OpenSslError.generalError(1, "error")
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }
        openSslHelper.mocked_createCsr_withWrappedkeyWrappedPointerOf_OpaquePointer_forRequestCsrModel_withInfoCertInfo_String = { _, _, _ in
            throw error
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: error)
        }
    }

    func testCreateCertCreateCertError() async throws {
        let error = OpenSslError.generalError(1, "error")
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }
        openSslHelper.mocked_createCsr_withWrappedkeyWrappedPointerOf_OpaquePointer_forRequestCsrModel_withInfoCertInfo_String = { _, _, _ in
            return ""
        }
        openSslHelper.mocked_createCert_forCsrString_withCakeyData_certCacertData_Data = { _, _, _ in throw error }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: error)
        }
    }

    func testCreateCertImportCertError() async throws {
        let error = Pkcs11Error.internalError()
        token.mocked_importCert__CertData_forIdString_Void = { _, _ in
            throw error
        }
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }
        openSslHelper.mocked_createCsr_withWrappedkeyWrappedPointerOf_OpaquePointer_forRequestCsrModel_withInfoCertInfo_String = { _, _, _ in
            return ""
        }
        openSslHelper.mocked_createCert_forCsrString_withCakeyData_certCacertData_Data = { _, _, _ in return Data() }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: error)
        }
    }

    func testCreateCertConnectionLostError() async throws {
        token.mocked_importCert__CertData_forIdString_Void = { _, _ in
            throw Pkcs11Error.internalError(rv: 10)
        }
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }

        pkcs11Helper.mocked_isPresent__SlotCK_SLOT_ID_Bool = { _ in return false }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }
        openSslHelper.mocked_createCsr_withWrappedkeyWrappedPointerOf_OpaquePointer_forRequestCsrModel_withInfoCertInfo_String = { _, _, _ in
            return ""
        }
        openSslHelper.mocked_createCert_forCsrString_withCakeyData_certCacertData_Data = { _, _, _ in return Data() }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel())
            },
            throws: CryptoManagerError.connectionLost)
    }
}
