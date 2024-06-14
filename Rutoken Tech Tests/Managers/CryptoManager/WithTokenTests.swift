//
//  WithTokenTests.swift
//  Rutoken Tech Tests
//
//  Created by Ivan Poderegin on 26.12.2023.
//

import XCTest

import Combine

@testable import Rutoken_Tech


final class CryptoManagerWithTokenTests: XCTestCase {
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

    func testWithTokenUsbSuccess() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Token Login")
        let exp4 = XCTestExpectation(description: "Token Logout")
        let exp5 = XCTestExpectation(description: "CallBack")
        exp1.isInverted = true
        exp2.isInverted = true
        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        let token = TokenMock(serial: "12345678", currentInterface: .usb)
        token.loginCallback = { pin in
            XCTAssertEqual(pin, "123456")
            exp3.fulfill()
        }
        token.logoutCallback = {
            exp4.fulfill()
        }
        pkcs11Helper.tokenPublisher.send([token])

        await assertNoThrowAsync(try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "123456") { exp5.fulfill() })
        await fulfillment(of: [exp1, exp2, exp3, exp4, exp5], timeout: 0.3)
    }

    func testWithTokenNfcSuccess() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Token Login")
        let exp4 = XCTestExpectation(description: "Token Logout")
        let exp5 = XCTestExpectation(description: "CallBack")
        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        let token = TokenMock(serial: "12345678", currentInterface: .nfc)
        token.loginCallback = { pin in
            XCTAssertEqual(pin, "123456")
            exp3.fulfill()
        }
        token.logoutCallback = {
            exp4.fulfill()
        }
        pkcs11Helper.tokenPublisher.send([token])

        await assertNoThrowAsync(try await manager.withToken(connectionType: .nfc, serial: token.serial, pin: "123456") { exp5.fulfill() })
        await fulfillment(of: [exp1, exp2, exp3, exp4, exp5], timeout: 0.3)
    }

    func testWithTokenNoPinNoLoginLogoutSuccess() async {
        let exp1 = XCTestExpectation(description: "CallBack")
        let exp2 = XCTestExpectation(description: "Token Login")
        let exp3 = XCTestExpectation(description: "Token Logout")
        exp2.isInverted = true
        exp3.isInverted = true
        let token = TokenMock(serial: "12345678", currentInterface: .nfc)
        token.loginCallback = { _ in
            exp2.fulfill()
        }
        token.logoutCallback = {
            exp3.fulfill()
        }
        pkcs11Helper.tokenPublisher.send([token])

        await assertNoThrowAsync(try await manager.withToken(connectionType: .nfc, serial: token.serial, pin: nil) { exp1.fulfill() })
        await fulfillment(of: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testWithTokenConnectionLostNfcError() async {
        let token = TokenMock(serial: "12345678", currentInterface: .nfc)
        pkcs11Helper.tokenPublisher.send([token])

        token.loginCallback = { _ in
            throw Pkcs11Error.tokenDisconnected
        }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .nfc, serial: "12345678", pin: "12345678") { },
            throws: CryptoManagerError.connectionLost)
    }

    func testWithTokenExchangeIsOverNfc() async {
        pcscHelper.nfcExchangeIsStoppedCallback = {
            Future<Void, Never>({ promise in
                Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    promise(.success(()))
                }
            }).eraseToAnyPublisher()
        }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .nfc, serial: nil, pin: nil) {},
            throws: CryptoManagerError.tokenNotFound)
    }

    func testWithTokenCancelledByUserErrorNfc() async {
        pcscHelper.startNfcCallback = {
            throw NfcError.cancelledByUser
        }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .nfc, serial: nil, pin: nil) {},
            throws: CryptoManagerError.nfcStopped)
    }

    func testWithTokenIncorrectPinError() async {
        let exp = XCTestExpectation(description: "Token Logout")
        exp.isInverted = true

        let token = TokenMock(serial: "12345678", currentInterface: .usb)
        pkcs11Helper.tokenPublisher.send([token])

        token.loginCallback = { _ in
            throw Pkcs11Error.incorrectPin
        }
        token.logoutCallback = {
            exp.fulfill()
        }

        let attempts: UInt = 2
        token.getPinAttemptsCallback = { attempts  }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: "12345678", pin: "incorrectPin") {},
            throws: CryptoManagerError.incorrectPin(attempts))
        await fulfillment(of: [exp], timeout: 0.3)
    }

    func testWithTokenWrongTokenError() async {
        let token = TokenMock(serial: "12345678", currentInterface: .usb)
        pkcs11Helper.tokenPublisher.send([token])

        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: "WrongSerial", pin: "123456") {},
            throws: CryptoManagerError.wrongToken)
    }

    func testWithTokenKeyNotFoundError() async {
        let token = TokenMock(serial: "12345678", currentInterface: .usb)
        token.loginCallback = { pin in
            XCTAssertEqual(pin, "123456")
        }
        pkcs11Helper.tokenPublisher.send([token])

        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "123456") {
                throw Pkcs11Error.internalError()
            },
            throws: CryptoManagerError.unknown)
    }
}
