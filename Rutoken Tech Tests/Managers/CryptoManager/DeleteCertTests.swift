//
//  DeleteCertTests.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 03.06.2024.
//

import XCTest

@testable import Rutoken_Tech


final class CryptoManagerDeleteCertTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: FileHelperMock!
    var token: TokenMock!

    let someId = "some id"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = FileHelperMock()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper, openSslHelper: openSslHelper, fileHelper: fileHelper)

        token = TokenMock(serial: "87654321", currentInterface: .usb)
        pkcs11Helper.tokenPublisher.send([token])
    }

    func testDeleteCertSuccess() async throws {
        token.deleteCertCallback = { id in
            XCTAssertEqual(id, self.someId)
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertNoThrowAsync(try await manager.deleteCert(with: someId))
        }
    }

    func testDeleteCertTokenNotFoundError() async {
        await assertErrorAsync(
            try await manager.deleteCert(with: someId),
            throws: CryptoManagerError.tokenNotFound)
    }

    func testDeleteCertError() async throws {
        token.deleteCertCallback = { _ in
            throw Pkcs11TokenError.keyNotFound
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.deleteCert(with: someId),
                throws: Pkcs11TokenError.keyNotFound)
        }
    }
}
