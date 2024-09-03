//
//  SignDocumentByCertIdTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 10.04.2024.
//

import Combine
import XCTest

@testable import Rutoken_Tech


class SignDocumentByCertIdTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: RtMockPkcs11HelperProtocol!
    var pcscHelper: RtMockPcscHelperProtocol!
    var openSslHelper: RtMockOpenSslHelperProtocol!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!

    var token: RtMockPkcs11TokenProtocol!
    var tokensPublisher: CurrentValueSubject<[Pkcs11TokenProtocol], Never>!

    var keyId: String!
    var dataToSign: Data!
    var signed: String!

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

        keyId = "123"
        dataToSign = Data("Data to sign".utf8)
        signed = "12345678qwerty"
    }

    func testSignDocumentTokenSuccess() async throws {
        let userCert = "user cert".data(using: .utf8)!
        let caCert = "ca cert".data(using: .utf8)!
        // swiftlint:disable:next line_length
        openSslHelper.mocked_signDocument__DocumentData_wrappedKeyWrappedPointerOf_OpaquePointer_certData_certChainArrayOf_Data_String = { content, _, cert, chain in
            XCTAssertEqual(content, self.dataToSign)
            XCTAssertEqual(cert, userCert)
            XCTAssertEqual(chain, [caCert])
            return self.signed
        }
        token.mocked_enumerateCerts_byIdString_ArrayOf_Pkcs11ObjectProtocol = {
            XCTAssertEqual($0, self.keyId)
            var object = Pkcs11ObjectMock()
            object.setValue(forAttr: .value, value: .success(userCert))
            return [object]
        }
        token.mocked_getWrappedKey_withIdString_WrappedPointerOf_OpaquePointer = {
            XCTAssertEqual($0, self.keyId)
            return WrappedPointer<OpaquePointer>({
                OpaquePointer.init(bitPattern: 1)!
            }, { _ in})!
        }

        let someUrl = URL(fileURLWithPath: "someurl")
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { file, dir in
            XCTAssertEqual(file, RtFile.caCert.rawValue)
            XCTAssertEqual(dir, .credentials)
            return someUrl
        }

        fileHelper.mocked_readFile_fromUrlURL_Data = { url in
            XCTAssertEqual(url, someUrl)
            return caCert
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            let result = try manager.signDocument(dataToSign, certId: keyId)
            XCTAssertEqual(signed, result)
        }
    }

    func testSignDocumentTokenNotFoundError() throws {
        assertError(try manager.signDocument(dataToSign, certId: keyId), throws: CryptoManagerError.tokenNotFound)
    }

    func testSignDocumentTokenError() async throws {
        let error = Pkcs11Error.internalError()
        token.mocked_getWrappedKey_withIdString_WrappedPointerOf_OpaquePointer = {
            XCTAssertEqual($0, self.keyId)
            throw error
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(dataToSign, certId: keyId), throws: error)
        }
    }

    func testSignDocumentConnectionLostError() async throws {
        token.mocked_enumerateCerts_byIdString_ArrayOf_Pkcs11ObjectProtocol = { _ in
            throw Pkcs11Error.internalError()
        }
        pkcs11Helper.mocked_isPresent__SlotCK_SLOT_ID_Bool = { _ in
            return false
        }
        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
                _ = try manager.signDocument(dataToSign, certId: keyId)
            },
            throws: CryptoManagerError.connectionLost)
    }

    func testSignDocumentNoSuitCertError() async throws {
        token.mocked_enumerateCerts_byIdString_ArrayOf_Pkcs11ObjectProtocol = {
            XCTAssertEqual($0, self.keyId)
            return []
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(dataToSign, certId: keyId), throws: CryptoManagerError.noSuitCert)
        }
    }

    func testSignDocumentGetUrlError() async throws {
        token.mocked_enumerateCerts_byIdString_ArrayOf_Pkcs11ObjectProtocol = {
            XCTAssertEqual($0, self.keyId)
            return [Pkcs11ObjectMock()]
        }

        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in nil }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(dataToSign, certId: keyId), throws: CryptoManagerError.unknown)
        }
    }

    func testSignDocumentReadFileError() async throws {
        let error = FileHelperError.generalError(32, "FileHelper error")
        token.mocked_enumerateCerts_byIdString_ArrayOf_Pkcs11ObjectProtocol = {
            XCTAssertEqual($0, self.keyId)
            return [Pkcs11ObjectMock()]
        }

        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in
            throw error
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(dataToSign, certId: keyId), throws: error)
        }
    }

    func testSignDocumentTokenOpenSslError() async throws {
        let error = OpenSslError.generalError(100, "error")
        // swiftlint:disable:next line_length
        openSslHelper.mocked_signDocument__DocumentData_wrappedKeyWrappedPointerOf_OpaquePointer_certData_certChainArrayOf_Data_String = { _, _, _, _ in
            throw error
        }
        token.mocked_enumerateCerts_byIdString_ArrayOf_Pkcs11ObjectProtocol = {
            XCTAssertEqual($0, self.keyId)
            return [Pkcs11ObjectMock()]
        }
        token.mocked_getWrappedKey_withIdString_WrappedPointerOf_OpaquePointer = {
            XCTAssertEqual($0, self.keyId)
            return WrappedPointer<OpaquePointer>({
                OpaquePointer.init(bitPattern: 1)!
            }, { _ in})!
        }
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            assertError(try manager.signDocument(dataToSign, certId: self.keyId), throws: error)
        }
    }
}
