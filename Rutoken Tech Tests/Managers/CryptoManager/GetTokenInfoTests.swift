//
//  GetTokenInfoTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 22.12.2023.
//

import Combine
import XCTest

@testable import Rutoken_Tech


class CryptoManagerGetTokenInfoTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper = Pkcs11HelperMock()
    var pcscHelper = PcscHelperMock()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper)
    }

    func testGetTokenInfoConnectionSuccessUsb() async {
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

        let token = TokenMock(connectionType: .usb)
        pkcs11Helper.tokenPublisher.send([token])
        let tokenInfo = try? await manager.getTokenInfo(for: .usb)
        XCTAssertEqual(tokenInfo, token.getInfo())
        await fulfillment(of: [exp1, exp2], timeout: 0.3)
    }

    func testGetTokenInfoConnectionSuccessNfc() async {
        let token = TokenMock(connectionType: .nfc)

        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")

        pcscHelper.startNfcCallback = {
            exp1.fulfill()
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }
        pkcs11Helper.tokenPublisher.send([token])
        let tokenInfo = try? await manager.getTokenInfo(for: .nfc)
        XCTAssertEqual(tokenInfo, token.getInfo())

        await fulfillment(of: [exp1, exp2], timeout: 0.3)
    }

    func testGetTokenInfoNfcCancelledByUserError() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")

        pcscHelper.startNfcCallback = {
            exp1.fulfill()
            throw NfcError.cancelledByUser
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }

        await assertErrorAsync(try await manager.getTokenInfo(for: .nfc), throws: CryptoManagerError.nfcStopped)
        await fulfillment(of: [exp1, exp2], timeout: 0.3)
    }

    func testGetTokenInfoNfcTimeoutError() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Wait for token")
        exp3.isInverted = true

        pcscHelper.startNfcCallback = {
            exp1.fulfill()
            throw NfcError.timeout
        }
        pcscHelper.stopNfcCallback = {
            exp2.fulfill()
        }

        await assertErrorAsync(try await manager.getTokenInfo(for: .nfc), throws: CryptoManagerError.nfcStopped)
        await fulfillment(of: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testGetTokenInfoNotFoundError() async {
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

        await assertErrorAsync(try await manager.getTokenInfo(for: .usb), throws: CryptoManagerError.tokenNotFound)
        await fulfillment(of: [exp1, exp2], timeout: 0.3)
    }

    func testGetTokenInfoNfcExchangeIsOver() async {
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

        await assertErrorAsync(try await manager.getTokenInfo(for: .nfc), throws: CryptoManagerError.tokenNotFound)
        await fulfillment(of: [exp1, exp2], timeout: 0.3)
    }
}
