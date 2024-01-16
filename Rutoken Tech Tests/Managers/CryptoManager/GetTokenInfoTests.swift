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
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper, openSslHelper: openSslHelper)
    }

    func testGetTokenInfoConnectionSuccess() async throws {
        let token = TokenMock(serial: "87654321", connectionType: .usb)
        pkcs11Helper.tokenPublisher.send([token])

        var result: TokenInfo?
        try await manager.withToken(connectionType: .usb, serial: "87654321", pin: nil) {
            result = try await manager.getTokenInfo()
        }
        XCTAssertEqual(result, token.getInfo())
    }

    func testGetTokenInfoNotFoundError() async {
        await assertErrorAsync(
            try await manager.getTokenInfo(),
            throws: CryptoManagerError.tokenNotFound)
    }
}
