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
        let caKeyData = Data("key".utf8)
        let caCertData = Data("cert".utf8)
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

        let privateKey = RtMockPkcs11ObjectProtocol()
        let startData = Data("20230101".utf8)
        let endData = Data("20240101".utf8)
        privateKey.mocked_getValue_forAttrAttrtypePkcs11DataAttribute_Data = { attr in
            switch attr {
            case .startDate: return startData
            case .endDate: return endData
            default: throw Pkcs11Error.internalError(rv: 1)
            }
        }
        let certInfo = CertInfo(startDate: startData.getDate(with: "YYYYMMdd"),
                                endDate: endData.getDate(with: "YYYYMMdd"))
        token.mocked_enumerateKey_byIdString_Pkcs11KeyPair = { _ in
            return Pkcs11KeyPair(publicKey: RtMockPkcs11ObjectProtocol(),
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

    func testCreateCertReadFileFromBundleError() async throws {
        let error = DocumentManagerError.general("")
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in throw error }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: error)
        }
    }

    func testCreateCertEnumerateKeyError() async throws {
        let error = Pkcs11Error.internalError(rv: 1)
        token.mocked_enumerateKey_byIdString_Pkcs11KeyPair = { _ in throw error }
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: error)
        }
    }

    func testCreateCertPrivateKeyUsagePeriodGetValueError() async throws {
        let error = Pkcs11Error.internalError(rv: 1)
        token.mocked_enumerateKey_byIdString_Pkcs11KeyPair = { _ in
            let object = RtMockPkcs11ObjectProtocol()
            object.mocked_getValue_forAttrAttrtypePkcs11DataAttribute_Data = { _ in throw error }
            return Pkcs11KeyPair(publicKey: object, privateKey: object)
        }
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: error)
        }
    }

    func testCreateCertWrappedKeyError() async throws {
        let error = Pkcs11Error.internalError(rv: 1)
        token.mocked_getWrappedKey_withIdString_WrappedPointerOf_OpaquePointer = { _ in
            throw error
        }
        token.mocked_enumerateKey_byIdString_Pkcs11KeyPair = { _ in
            let pKey = RtMockPkcs11ObjectProtocol()
            pKey.mocked_getValue_forAttrAttrtypePkcs11DataAttribute_Data = { _ in Data() }
            return Pkcs11KeyPair(publicKey: RtMockPkcs11ObjectProtocol(),
                                 privateKey: pKey)
        }
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.createCert(for: "001", with: CsrModel.makeDefaultModel()),
                throws: error)
        }
    }

    func testCreateCertCreateCsrError() async throws {
        let error = OpenSslError.generalError(1, "error")
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }
        token.mocked_enumerateKey_byIdString_Pkcs11KeyPair = { _ in
            let pKey = RtMockPkcs11ObjectProtocol()
            pKey.mocked_getValue_forAttrAttrtypePkcs11DataAttribute_Data = { _ in Data() }
            return Pkcs11KeyPair(publicKey: RtMockPkcs11ObjectProtocol(),
                                 privateKey: pKey)
        }
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

        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }
        token.mocked_enumerateKey_byIdString_Pkcs11KeyPair = { _ in
            let pKey = RtMockPkcs11ObjectProtocol()
            pKey.mocked_getValue_forAttrAttrtypePkcs11DataAttribute_Data = { _ in Data() }
            return Pkcs11KeyPair(publicKey: RtMockPkcs11ObjectProtocol(),
                                 privateKey: pKey)
        }

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
        token.mocked_enumerateKey_byIdString_Pkcs11KeyPair = { _ in
            let pKey = RtMockPkcs11ObjectProtocol()
            pKey.mocked_getValue_forAttrAttrtypePkcs11DataAttribute_Data = { _ in Data() }
            return Pkcs11KeyPair(publicKey: RtMockPkcs11ObjectProtocol(),
                                 privateKey: pKey)
        }

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
        token.mocked_enumerateKey_byIdString_Pkcs11KeyPair = { _ in
            let pKey = RtMockPkcs11ObjectProtocol()
            pKey.mocked_getValue_forAttrAttrtypePkcs11DataAttribute_Data = { _ in Data() }
            return Pkcs11KeyPair(publicKey: RtMockPkcs11ObjectProtocol(),
                                 privateKey: pKey)
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
