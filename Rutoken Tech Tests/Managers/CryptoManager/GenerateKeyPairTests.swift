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

    func testGenerateKeyPairSuccess() async throws {
        tokensPublisher.send([token])
        let keyId = Data.random()

        token.mocked_generateKeyPair_withIdData_Void = { id in
            XCTAssertEqual(id, keyId)
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "123456") {
            await assertNoThrowAsync(try await manager.generateKeyPair(with: keyId))
        }
    }

    func testGenerateKeyPairConnectionLostErrorError() async {
        tokensPublisher.send([token])

        token.mocked_generateKeyPair_withIdData_Void = { _ in
            throw Pkcs11Error.internalError(rv: 10)
        }
        pkcs11Helper.mocked_isPresent__SlotCK_SLOT_ID_Bool = { _ in
            return false
        }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "123456") {
                try await manager.generateKeyPair(with: Data.random())
            }, throws: CryptoManagerError.connectionLost)
    }

    func testGenerateKeyPairTokenNotFoundError() async {
        await assertErrorAsync(
            try await manager.generateKeyPair(with: Data.random()),
            throws: CryptoManagerError.tokenNotFound)
    }
}
