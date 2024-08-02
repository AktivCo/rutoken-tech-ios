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

    func testGenerateKeyPairSuccess() async throws {
        let token = TokenMock(serial: "12345678", currentInterface: .usb)
        tokensPublisher.send([token])

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "123456") {
            await assertNoThrowAsync(try await manager.generateKeyPair(with: "qwerty"))
        }
    }

    func testGenerateKeyPairConnectionLostErrorError() async {
        let token = TokenMock(serial: "12345678", currentInterface: .usb)
        tokensPublisher.send([token])

        token.generateKeyPairCallback = { _ in
            throw Pkcs11Error.internalError(rv: 10)
        }
        pkcs11Helper.mocked_isPresent__SlotCK_SLOT_ID_Bool = { _ in
            return false
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
