//
//  GenerateKeyPairTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 22.12.2023.
//

import XCTest

@testable import Rutoken_Tech


class CryptoManagerGenerateKeyPairTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)
    }

    func testGenerateKeyPairSuccess() async throws {
        let token = TokenMock(serial: "12345678", currentInterface: .usb)
        pkcs11Helper.tokenPublisher.send([token])

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "123456") {
            await assertNoThrowAsync(try await manager.generateKeyPair(with: "qwerty"))
        }
    }

    func testGenerateKeyPairConnectionLostErrorError() async {
        let token = TokenMock(serial: "12345678", currentInterface: .usb)
        pkcs11Helper.tokenPublisher.send([token])
        token.generateKeyPairCallback = { _ in
            throw Pkcs11Error.internalError(rv: 10)
        }
        pkcs11Helper.isPresentCallback = { _ in
            return false
        }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: "12345678", pin: "123456") {
                try await manager.generateKeyPair(with: "123456")
            }, throws: CryptoManagerError.connectionLost)
    }

    func testGenerateKeyPairTokenNotFoundError() async {
        await assertErrorAsync(
            try await manager.generateKeyPair(with: "123456"),
            throws: CryptoManagerError.tokenNotFound)
    }
}
