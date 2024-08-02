//
//  EnumerateKeysTests.swift
//  Rutoken Tech Tests
//
//  Created by Ivan Poderegin on 27.12.2023.
//

import Combine
import XCTest

@testable import Rutoken_Tech


final class CryptoManagerEnumerateKeysTests: XCTestCase {
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

    func testEnumerateKeysConnectionSuccess() async throws {
        let token = TokenMock(serial: "87654321", currentInterface: .usb)
        let testId = "some id"

        tokensPublisher.send([token])
        token.enumerateKeysWithAlgoCallback = { _ in
            var object = Pkcs11ObjectMock()
            object.setValue(forAttr: .id, value: .success(Data(testId.utf8)))
            return [Pkcs11KeyPair(publicKey: object, privateKey: object)]
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

    func testEnumerateKeysConnectionLostError() async throws {
        let token = TokenMock(serial: "87654321", currentInterface: .usb)
        tokensPublisher.send([token])
        token.enumerateKeysWithAlgoCallback = { _ in
            throw Pkcs11Error.internalError()
        }
        pkcs11Helper.mocked_isPresent__SlotCK_SLOT_ID_Bool = { _ in
            return false
        }
        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
                _ = try await manager.enumerateKeys()
            },
            throws: CryptoManagerError.connectionLost)
    }
}
