//
//  DeleteCertTests.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 03.06.2024.
//

import Combine
import XCTest

@testable import Rutoken_Tech


final class CryptoManagerDeleteCertTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: RtMockPkcs11HelperProtocol!
    var pcscHelper: RtMockPcscHelperProtocol!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!
    var token: RtMockPkcs11TokenProtocol!
    var tokensPublisher: CurrentValueSubject<[Pkcs11TokenProtocol], Never>!

    let someId = "some id"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = RtMockPkcs11HelperProtocol()
        pcscHelper = RtMockPcscHelperProtocol()
        openSslHelper = OpenSslHelperMock()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()

        token = RtMockPkcs11TokenProtocol()
        token.setup()
        tokensPublisher = CurrentValueSubject<[Pkcs11TokenProtocol], Never>([token])
        pkcs11Helper.mocked_tokens = tokensPublisher.eraseToAnyPublisher()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)
    }

    func testDeleteCertSuccess() async throws {
        token.mocked_deleteCert_withIdString_Void = { id in
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
        token.mocked_deleteCert_withIdString_Void = { _ in
            throw Pkcs11Error.internalError()
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
            await assertErrorAsync(
                try await manager.deleteCert(with: someId),
                throws: Pkcs11Error.internalError())
        }
    }

    func testDecryptCmsConnectionLostError() async throws {
        token.mocked_deleteCert_withIdString_Void = { _ in
            throw Pkcs11Error.internalError()
        }
        pkcs11Helper.mocked_isPresent__SlotCK_SLOT_ID_Bool = { _ in
            return false
        }
        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "12345678") {
                try await manager.deleteCert(with: someId)
            },
            throws: CryptoManagerError.connectionLost)
    }
}
