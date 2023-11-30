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

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper)
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
        let token = TokenMock(serial: "12345678", connectionType: .usb)
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
        let token = TokenMock(serial: "12345678", connectionType: .nfc)
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

    func testWithTokenConnectionLostNfcError() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        let token = TokenMock(serial: "12345678", connectionType: .nfc)
        pkcs11Helper.tokenPublisher.send([token])

        token.loginCallback = { _ in
            throw TokenError.tokenDisconnected
        }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .nfc, serial: "12345678", pin: "12345678") { },
            throws: CryptoManagerError.connectionLost)
        await fulfillment(of: [exp1, exp2], timeout: 0.3)
    }

    func testWithTokenExchangeIsOverNfc() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }

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
        await fulfillment(of: [exp1, exp2], timeout: 0.3)
    }

    func testWithTokenCancelledByUserErrorNfc() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")

        pcscHelper.startNfcCallback = {
            exp1.fulfill()
            throw NfcError.cancelledByUser
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }

        await assertErrorAsync(try await manager.withToken(connectionType: .nfc, serial: nil, pin: nil) {},
                               throws: CryptoManagerError.nfcStopped)
        await fulfillment(of: [exp1, exp2], timeout: 0.3)
    }

    func testWithTokenIncorrectPinUsbError() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Token Logout")
        exp1.isInverted = true
        exp2.isInverted = true
        exp3.isInverted = true
        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        let token = TokenMock(serial: "12345678", connectionType: .usb)
        pkcs11Helper.tokenPublisher.send([token])

        token.loginCallback = { _ in
            throw TokenError.incorrectPin(attemptsLeft: 2)
        }
        token.logoutCallback = {
            exp3.fulfill()
        }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: "12345678", pin: "incorrectPin") {},
            throws: CryptoManagerError.incorrectPin(2))
        await fulfillment(of: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testWithTokenIncorrectPinNfcError() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Token Logout")
        exp3.isInverted = true
        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        let token = TokenMock(serial: "12345678", connectionType: .nfc)
        pkcs11Helper.tokenPublisher.send([token])

        token.loginCallback = { _ in
            throw TokenError.incorrectPin(attemptsLeft: 2)
        }
        token.logoutCallback = {
            exp3.fulfill()
        }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .nfc, serial: "12345678", pin: "incorrectPin") {},
            throws: CryptoManagerError.incorrectPin(2))
        await fulfillment(of: [exp1, exp2, exp3], timeout: 0.3)
    }

     func testWithTokenWrongTokenUsbError() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        exp1.isInverted = true
        exp2.isInverted = true
        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }

        let token = TokenMock(serial: "12345678", connectionType: .usb)
        pkcs11Helper.tokenPublisher.send([token])

        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: "WrongSerial", pin: "123456") {},
            throws: CryptoManagerError.wrongToken)
        await fulfillment(of: [exp1, exp2], timeout: 0.3)
     }

     func testWithTokenWrongTokenNfcError() async {
         let exp1 = XCTestExpectation(description: "Start Nfc")
         let exp2 = XCTestExpectation(description: "Stop Nfc")
         pcscHelper.startNfcCallback = {
             exp1.fulfill()
         }
         pcscHelper.stopNfcCallback = {
             exp2.fulfill()
         }

         let token = TokenMock(serial: "12345678", connectionType: .nfc)
         pkcs11Helper.tokenPublisher.send([token])

         await assertErrorAsync(
             try await manager.withToken(connectionType: .nfc, serial: "WrongSerial", pin: "123456") {},
             throws: CryptoManagerError.wrongToken)
         await fulfillment(of: [exp1, exp2], timeout: 0.3)
     }
}
