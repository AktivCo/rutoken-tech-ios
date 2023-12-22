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
    var pkcs11Helper = Pkcs11HelperMock()
    var pcscHelper = PcscHelperMock()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper)
    }

    func testGenerateKeyPairUsbSuccess() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Token Login")
        let exp4 = XCTestExpectation(description: "Token generate keyPair")
        let exp5 = XCTestExpectation(description: "Token Logout")
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
            exp5.fulfill()
        }
        token.generateKeyPairCallback = { keyId in
            XCTAssertEqual(keyId, "qwerty")
            exp4.fulfill()
        }
        pkcs11Helper.tokenPublisher.send([token])

        await assertNoThrowAsync(try await manager.generateKeyPair(for: .usb, serial: token.serial, pin: "123456", keyId: "qwerty"))
        await fulfillment(of: [exp1, exp2, exp3, exp4, exp5], timeout: 0.3)
    }

    func testGenerateKeyPairUsbWrongTokenError() async {
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
            try await manager.generateKeyPair(for: .usb, serial: "WrongSerial", pin: "123456", keyId: "123456"),
            throws: CryptoManagerError.wrongToken)
        await fulfillment(of: [exp1, exp2], timeout: 0.3)
    }

    func testGenerateKeyPairUsbTokenDisconnectedError() async {
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
        token.generateKeyPairCallback = { _ in
            throw TokenError.tokenDisconnected
        }

        await assertErrorAsync(
            try await manager.generateKeyPair(for: .usb, serial: "12345678", pin: "123456", keyId: "123456"),
            throws: CryptoManagerError.connectionLost)
        await fulfillment(of: [exp1, exp2], timeout: 0.3)
    }

    func testGenerateKeyPairUsbWrongPin() async {
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
            throw TokenError.incorrectPin(attemptsLeft: 7)
        }
        token.logoutCallback = {
            exp3.fulfill()
        }

        await assertErrorAsync(
            try await manager.generateKeyPair(for: .usb, serial: "12345678", pin: "123456", keyId: "123456"),
            throws: CryptoManagerError.incorrectPin(7))
        await fulfillment(of: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testGenerateKeyPairUsbTokenNotFoundError() async {
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
        let token = TokenMock(serial: "12345678", connectionType: .nfc)
        pkcs11Helper.tokenPublisher.send([token])
        await assertErrorAsync(
            try await manager.generateKeyPair(for: .usb, serial: "12345678", pin: "123456", keyId: "123456"),
            throws: CryptoManagerError.tokenNotFound)
        await fulfillment(of: [exp1, exp2], timeout: 0.3)
    }

    func testGenerateKeyPairNfcSuccess() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Token Login")
        let exp4 = XCTestExpectation(description: "Token generate keyPair")
        let exp5 = XCTestExpectation(description: "Token Logout")
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
            exp5.fulfill()
        }
        token.generateKeyPairCallback = { keyId in
            XCTAssertEqual(keyId, "qwerty")
            exp4.fulfill()
        }
        pkcs11Helper.tokenPublisher.send([token])

        await assertNoThrowAsync(try await manager.generateKeyPair(for: .nfc, serial: token.serial, pin: "123456", keyId: "qwerty"))
        await fulfillment(of: [exp1, exp2, exp3, exp4, exp5], timeout: 0.3)
    }

    func testGenerateKeyPairNfcWrongTokenError() async {
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
            try await manager.generateKeyPair(for: .nfc, serial: "WrongSerial", pin: "123456", keyId: "123456"),
            throws: CryptoManagerError.wrongToken)
        await fulfillment(of: [exp1, exp2], timeout: 0.3)
    }

    func testGenerateKeyPairNfcTokenDisconnectedError() async {
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
        token.generateKeyPairCallback = { _ in
            throw TokenError.tokenDisconnected
        }

        await assertErrorAsync(
            try await manager.generateKeyPair(for: .nfc, serial: "12345678", pin: "123456", keyId: "123456"),
            throws: CryptoManagerError.connectionLost)
        await fulfillment(of: [exp1, exp2], timeout: 0.3)
    }

    func testGenerateKeyPairNfcWrongPin() async {
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
            throw TokenError.incorrectPin(attemptsLeft: 7)
        }
        token.logoutCallback = {
            exp3.fulfill()
        }

        await assertErrorAsync(
            try await manager.generateKeyPair(for: .nfc, serial: "12345678", pin: "123456", keyId: "123456"),
            throws: CryptoManagerError.incorrectPin(7))
        await fulfillment(of: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testGenerateKeyPairNfcExchangeIsOver() async {
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
            try await manager.generateKeyPair(for: .nfc, serial: "123456", pin: "12345678", keyId: "qwerty"),
            throws: CryptoManagerError.tokenNotFound)
        await fulfillment(of: [exp1, exp2], timeout: 0.3)
    }
}
