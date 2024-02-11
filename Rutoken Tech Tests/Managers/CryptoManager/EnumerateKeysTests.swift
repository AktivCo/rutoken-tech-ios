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

    func testEnumerateKeysConnectionSuccess() async throws {
        let token = TokenMock(serial: "87654321", currentInterface: .usb)
        let testId = "some id"

        pkcs11Helper.tokenPublisher.send([token])

        token.enumerateKeysCallback = { _ in
            return [Pkcs11KeyPair(pubKey: Pkcs11ObjectMock(id: testId, body: nil),
                                  privateKey: Pkcs11ObjectMock(id: testId, body: nil))]
        }

        var result: [KeyModel]?
        try await manager.withToken(connectionType: .usb, serial: "87654321", pin: nil) {
            result = try await manager.enumerateKeys()
        }
        XCTAssertEqual(result, [.init(ckaId: testId, type: .gostR3410_2012_256)])
    }

    func testEnumerateKeysTokenNotFoundError() async {
        await assertErrorAsync(try await manager.enumerateKeys(),
                               throws: CryptoManagerError.tokenNotFound)
    }
}

