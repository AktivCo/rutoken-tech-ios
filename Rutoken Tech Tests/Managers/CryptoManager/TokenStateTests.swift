//
//  TokenStateTests.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 28.05.2024.
//

import XCTest

@testable import Rutoken_Tech


final class CryptoManageTokenStateTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!

    var nfcToken: TokenMock!
    var usbToken: TokenMock!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)

        usbToken = TokenMock(serial: "12345678", currentInterface: .usb)
        nfcToken = TokenMock(serial: "87654321", currentInterface: .nfc)
        pkcs11Helper.tokenPublisher.send([usbToken, nfcToken])
    }

    func testUsbStates() async throws {
        let states = try await awaitPublisherUnwrapped(manager.tokenState.collect(2)) {
            try await manager.withToken(connectionType: .usb, serial: usbToken.serial, pin: nil) {}
        }
        XCTAssertEqual(states, [.inProgress, .ready])
    }

    func testUsbStatesIgnoreNfcCooldown() async throws {
        pcscHelper.nfcCooldownCounter = AsyncThrowingStream { con in
            con.yield(5)
            con.finish(throwing: CryptoManagerError.unknown)
        }
        let states = try await awaitPublisherUnwrapped(manager.tokenState.collect(2)) {
            try await manager.withToken(connectionType: .usb, serial: usbToken.serial, pin: nil) {}
        }
        XCTAssertEqual(states, [.inProgress, .ready])
    }

    func testNfcStates() async throws {
        pcscHelper.nfcCooldownCounter = AsyncThrowingStream { con in
            con.yield(5)
            con.yield(2)
            con.yield(0)
            con.finish()
        }
        let states = try await awaitPublisherUnwrapped(manager.tokenState.collect(4)) {
            try await manager.withToken(connectionType: .nfc, serial: nfcToken.serial, pin: nil) {}
        }
        XCTAssertEqual(states, [.inProgress, .cooldown(5), .cooldown(2), .ready])
    }

    func testNfcStatesNfcCooldownError() async throws {
        pcscHelper.nfcCooldownCounter = AsyncThrowingStream { con in
            con.yield(5)
            con.finish(throwing: CryptoManagerError.unknown)
        }
        let states = try await awaitPublisherUnwrapped(manager.tokenState.collect(3)) {
            try await manager.withToken(connectionType: .nfc, serial: nfcToken.serial, pin: nil) {}
        }
        XCTAssertEqual(states, [.inProgress, .cooldown(5), .ready])
    }
}
