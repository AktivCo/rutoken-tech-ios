//
//  GetTokenInfoTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 22.12.2023.
//

import Combine
import XCTest

@testable import Rutoken_Tech


class CryptoManagerGetTokenInfoTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: RtMockPkcs11HelperProtocol!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!

    var tokensPublisher: CurrentValueSubject<[Pkcs11TokenProtocol], Never>!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = RtMockPkcs11HelperProtocol()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()

        tokensPublisher = CurrentValueSubject<[Pkcs11TokenProtocol], Never>([])
        pkcs11Helper.mocked_tokens = tokensPublisher.eraseToAnyPublisher()
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)
    }

    func testGetTokenInfoUsbSuccess() async throws {
        let token = TokenMock(serial: "87654321", currentInterface: .usb, supportedInterfaces: [.usb])
        tokensPublisher.send([token])

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
        tokensPublisher.send([token])

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
        tokensPublisher.send([token])

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
