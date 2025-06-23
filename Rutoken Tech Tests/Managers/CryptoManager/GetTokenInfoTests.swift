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

        tokensPublisher = CurrentValueSubject<[Pkcs11TokenProtocol], Never>([])
        pkcs11Helper.mocked_tokens = tokensPublisher.eraseToAnyPublisher()
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)
    }

    func testGetTokenInfoUsbSuccess() async throws {
        tokensPublisher.send([token])

        var result: TokenInfo?
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            result = try await manager.getTokenInfo()
        }
        XCTAssertEqual(result?.serial, token.serial)
        XCTAssertEqual(result?.label, token.label)
        XCTAssertEqual(result?.model, token.model)
        XCTAssertEqual(result?.type, .usb)
        XCTAssertEqual(result?.connectionType, .usb)
    }

    func testGetTokenInfoNfcSuccess() async throws {
        pcscHelper.mocked_startNfc_async_AsyncStreamOf_RtNfcSearchStatus = { [self] in
            AsyncStream { con in
                con.yield(.inProgress)
                token.mocked_currentInterface = .nfc
                token.mocked_supportedInterfaces = [.nfc]
                tokensPublisher.send([token])
                con.finish()
            }
        }
        pcscHelper.mocked_stopNfc_async_Void = {}
        pcscHelper.mocked_getNfcCooldown_AsyncThrowingStreamOf_UIntError = {
            AsyncThrowingStream { con in
                con.yield(0)
                con.finish()
            }
        }

        var result: TokenInfo?
        try await manager.withToken(connectionType: .nfc, serial: token.serial, pin: nil) {
            result = try await manager.getTokenInfo()
        }
        XCTAssertEqual(result?.serial, token.serial)
        XCTAssertEqual(result?.label, token.label)
        XCTAssertEqual(result?.model, token.model)
        XCTAssertEqual(result?.type, .sc)
        XCTAssertEqual(result?.connectionType, .nfc)
    }

    func testGetTokenInfoDualSuccess() async throws {
        token.mocked_supportedInterfaces = [.nfc, .usb]
        tokensPublisher.send([token])

        var result: TokenInfo?
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
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
