//
//  EnumerateKeysTests.swift
//  Rutoken Tech Tests
//
//  Created by Ivan Poderegin on 27.12.2023.
//

import XCTest

@testable import Rutoken_Tech


final class CryptoManagerEnumerateKeysTests: XCTestCase {
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

    func testEnumerateKeysConnectionSuccess() async throws {
        let token = TokenMock(serial: "87654321", connectionType: .usb)

        pkcs11Helper.tokenPublisher.send([token])

        let keys = [KeyModel(ckaId: "001", type: .gostR3410_2012_256)]
        token.getKeysCallback = { keys }

        var result: [KeyModel]?
        try await manager.withToken(connectionType: .usb, serial: "87654321", pin: nil) {
            result = try await manager.enumerateKeys()
        }
        XCTAssertEqual(keys, result)
    }

    func testEnumerateKeysTokenNotFoundError() async {
        await assertErrorAsync(try await manager.enumerateKeys(),
                               throws: CryptoManagerError.tokenNotFound)
    }
}

