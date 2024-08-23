//
//  DecryptCmsTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 20.05.2024.
//

import Combine
import XCTest

@testable import Rutoken_Tech


class CryptoManagerDecryptCmsTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: RtMockPkcs11HelperProtocol!
    var pcscHelper: RtMockPcscHelperProtocol!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!

    var token: TokenMock!
    var tokensPublisher: CurrentValueSubject<[Pkcs11TokenProtocol], Never>!
    var documentData: Data!
    var decryptedData: Data!
    var certId: String!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        pkcs11Helper = RtMockPkcs11HelperProtocol()
        pcscHelper = RtMockPcscHelperProtocol()
        openSslHelper = OpenSslHelperMock()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()

        token = TokenMock(serial: "87654321", currentInterface: .usb, supportedInterfaces: [.usb])
        tokensPublisher = CurrentValueSubject<[Pkcs11TokenProtocol], Never>([token])
        pkcs11Helper.mocked_tokens = tokensPublisher.eraseToAnyPublisher()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)

        certId = "certId"
        documentData = Data("data to decrypt".utf8)
        decryptedData = Data("decrypted data".utf8)
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
        pkcs11Helper.mocked_isPresent__SlotCK_SLOT_ID_Bool = { _ in
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
