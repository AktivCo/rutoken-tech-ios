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

        let token = TokenMock(connectionType: .usb)
        pkcs11Helper.getTokenResult = .success(token)

        XCTAssertEqual(try manager.getTokenInfo(for: .usb), token.getInfo())
        wait(for: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testGetTokenInfoConnectionSuccessNfc() {
        let token = TokenMock(connectionType: .nfc)
        pkcs11Helper.getTokenResult = .success(token)

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

        XCTAssertEqual(try manager.getTokenInfo(for: .nfc), token.getInfo())
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

        assertError(try manager.getTokenInfo(for: .nfc), throws: CryptoManagerError.nfcStopped)
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

        assertError(try manager.getTokenInfo(for: .nfc), throws: CryptoManagerError.nfcStopped)
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

        pkcs11Helper.getTokenResult = .failure(Pkcs11Error.tokenNotFound)

        assertError(try manager.getTokenInfo(for: .usb), throws: CryptoManagerError.tokenNotFound)
        wait(for: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testGetTokenInfoConnectionLostError() {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Wait for token")
        exp1.isInverted = true
        exp2.isInverted = true
        exp3.isInverted = true

        pkcs11Helper.getTokenResult = .failure(Pkcs11Error.connectionLost)
        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        pcscHelper.waitForTokenCallback = {
            exp3.fulfill()
        }

        assertError(try manager.getTokenInfo(for: .usb), throws: CryptoManagerError.connectionLost)
        wait(for: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testGetTokenInfoUnknownError() {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Wait for token")
        exp1.isInverted = true
        exp2.isInverted = true
        exp3.isInverted = true

        pkcs11Helper.getTokenResult = .failure(Pkcs11Error.unknownError)
        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        pcscHelper.waitForTokenCallback = {
            exp3.fulfill()
        }

        assertError(try manager.getTokenInfo(for: .usb), throws: CryptoManagerError.unknown)
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

        assertError(try manager.getTokenInfo(for: .nfc), throws: CryptoManagerError.unsupportedDevice)
        wait(for: [exp1, exp2, exp3], timeout: 0.3)
    }
}
