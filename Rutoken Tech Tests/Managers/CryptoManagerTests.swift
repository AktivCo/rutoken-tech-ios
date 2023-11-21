//
//  CryptoManagerTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 22.11.2023.
//

import XCTest

@testable import Rutoken_Tech


class CryptoManagerTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper = Pkcs11HelperMock()
    var pcscHelper = PcscHelperMock()
    var token = TokenMock()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper)
    }

    func testGetTokenInfoConnectionSuccessUsb() {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Wait for token")
        exp1.isInverted = true
        exp2.isInverted = true
        exp3.isInverted = true

        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        pcscHelper.waitForTokenCallback = {
            exp3.fulfill()
        }

        let token = TokenMock()
        let tokenInfo = TokenInfo(label: "success", serial: "123456", model: .rutoken3, supportedInterfaces: [.usb])
        token.getTokenInfoCallback = {
            tokenInfo
        }
        pkcs11Helper.getConnectedTokenCallback = { _ in
            return token
        }

        XCTAssertEqual(try manager.getTokenInfo(tokenInterface: .usb), tokenInfo)
        wait(for: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testGetTokenInfoConnectionSuccessNfc() {
        let token = TokenMock()
        let tokenInfo = TokenInfo(label: "success", serial: "123456", model: .rutoken3, supportedInterfaces: [.nfc])
        token.getTokenInfoCallback = {
            tokenInfo
        }
        pkcs11Helper.getConnectedTokenCallback = { _ in
            return token
        }

        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Wait for token")

        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        pcscHelper.waitForTokenCallback = {
            exp3.fulfill()
        }

        XCTAssertEqual(try manager.getTokenInfo(tokenInterface: .nfc), tokenInfo)
        wait(for: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testGetTokenInfoNfcCancelledByUserError() {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Wait for token")
        exp3.isInverted = true

        pcscHelper.startNfcCallback = {
            exp1.fulfill()
            throw StartNfcError.cancelledByUser
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        pcscHelper.waitForTokenCallback = {
            exp3.fulfill()
        }

        assertError(try manager.getTokenInfo(tokenInterface: .nfc), throws: CryptoManagerError.nfcStopped)
        wait(for: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testGetTokenInfoNfcTimeoutError() {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Wait for token")
        exp3.isInverted = true

        pcscHelper.startNfcCallback = {
            exp1.fulfill()
            throw StartNfcError.timeout
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        pcscHelper.waitForTokenCallback = {
            exp3.fulfill()
        }

        assertError(try manager.getTokenInfo(tokenInterface: .nfc), throws: CryptoManagerError.nfcStopped)
        wait(for: [exp1, exp2, exp3], timeout: 0.3)
    }


    func testGetTokenInfoNotFoundError() {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Wait for token")
        exp1.isInverted = true
        exp2.isInverted = true
        exp3.isInverted = true

        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        pcscHelper.waitForTokenCallback = {
            exp3.fulfill()
        }
        pkcs11Helper.getConnectedTokenCallback = { _ in
            throw Pkcs11Error.tokenNotFound
        }

        assertError(try manager.getTokenInfo(tokenInterface: .usb), throws: CryptoManagerError.tokenNotFound)
        wait(for: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testGetTokenInfoConnectionLostError() {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Wait for token")
        exp1.isInverted = true
        exp2.isInverted = true
        exp3.isInverted = true

        pkcs11Helper.getConnectedTokenCallback = { _ in
            throw Pkcs11Error.connectionLost
        }
        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        pcscHelper.waitForTokenCallback = {
            exp3.fulfill()
        }

        assertError(try manager.getTokenInfo(tokenInterface: .usb), throws: CryptoManagerError.connectionLost)
        wait(for: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testGetTokenInfoUnknownError() {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Wait for token")
        exp1.isInverted = true
        exp2.isInverted = true
        exp3.isInverted = true

        pkcs11Helper.getConnectedTokenCallback = { _ in
            throw Pkcs11Error.unknownError
        }
        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        pcscHelper.waitForTokenCallback = {
            exp3.fulfill()
        }

        assertError(try manager.getTokenInfo(tokenInterface: .usb), throws: CryptoManagerError.unknown)
        wait(for: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testGetTokenInfoUnsupportedDeviceError() {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Wait for token")
        exp3.isInverted = true
        pcscHelper.startNfcCallback = {
            exp1.fulfill()
            throw StartNfcError.unsupportedDevice
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        pcscHelper.waitForTokenCallback = {
            exp3.fulfill()
        }

        assertError(try manager.getTokenInfo(tokenInterface: .nfc), throws: CryptoManagerError.unsupportedDevice)
        wait(for: [exp1, exp2, exp3], timeout: 0.3)
    }
}
