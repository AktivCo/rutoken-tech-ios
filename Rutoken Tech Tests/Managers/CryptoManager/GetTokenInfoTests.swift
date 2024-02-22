//
//  GetTokenInfoTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 22.12.2023.
//

import XCTest

@testable import Rutoken_Tech


class CryptoManagerGetTokenInfoTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: FileHelperMock!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = FileHelperMock()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper)
    }

    func testGetTokenInfoUsbSuccess() async throws {
        let token = TokenMock(serial: "87654321", currentInterface: .usb, supportedInterfaces: [.usb])
        pkcs11Helper.tokenPublisher.send([token])

        var result: TokenInfo?
        try await manager.withToken(connectionType: .usb, serial: "87654321", pin: nil) {
            result = try await manager.getTokenInfo()
        }
        XCTAssertEqual(result?.serial, token.serial)
        XCTAssertEqual(result?.label, token.label)
        XCTAssertEqual(result?.model, token.model)
        XCTAssertEqual(result?.type, .usb)
        XCTAssertEqual(result?.connectionType, .usb)
    }

    func testGetTokenInfoNfcSuccess() async throws {
        let token = TokenMock(serial: "87654321", currentInterface: .nfc, supportedInterfaces: [.nfc])
        pkcs11Helper.tokenPublisher.send([token])

        var result: TokenInfo?
        try await manager.withToken(connectionType: .nfc, serial: "87654321", pin: nil) {
            result = try await manager.getTokenInfo()
        }
        XCTAssertEqual(result?.serial, token.serial)
        XCTAssertEqual(result?.label, token.label)
        XCTAssertEqual(result?.model, token.model)
        XCTAssertEqual(result?.type, .sc)
        XCTAssertEqual(result?.connectionType, .nfc)
    }

    func testGetTokenInfoDualSuccess() async throws {
        let token = TokenMock(serial: "87654321", currentInterface: .usb, supportedInterfaces: [.nfc, .usb])
        pkcs11Helper.tokenPublisher.send([token])

        var result: TokenInfo?
        try await manager.withToken(connectionType: .usb, serial: "87654321", pin: nil) {
            result = try await manager.getTokenInfo()
        }
        XCTAssertEqual(result?.serial, token.serial)
        XCTAssertEqual(result?.label, token.label)
        XCTAssertEqual(result?.model, token.model)
        XCTAssertEqual(result?.type, .dual)
        XCTAssertEqual(result?.connectionType, .usb)
    }

    func testGetTokenInfoNotFoundError() async {
        await assertErrorAsync(
            try await manager.getTokenInfo(),
            throws: CryptoManagerError.tokenNotFound)
    }
}
