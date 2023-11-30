//
//  GenerateKeyPairTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 22.12.2023.
//

import Combine
import XCTest

@testable import Rutoken_Tech


class CryptoManagerGenerateKeyPairTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper)
    }

    func testGenerateKeyPairSuccess() async throws {
        let token = TokenMock(serial: "12345678", connectionType: .usb)
        pkcs11Helper.tokenPublisher.send([token])

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "123456") {
            await assertNoThrowAsync(try await manager.generateKeyPair(with: "qwerty"))
        }
    }

    func testGenerateKeyPairTokenDisconnectedError() async {
        let token = TokenMock(serial: "12345678", connectionType: .usb)
        pkcs11Helper.tokenPublisher.send([token])
        token.generateKeyPairCallback = { _ in
            throw TokenError.tokenDisconnected
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
