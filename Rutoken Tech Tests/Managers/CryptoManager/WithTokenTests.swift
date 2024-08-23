//
//  WithTokenTests.swift
//  Rutoken Tech Tests
//
//  Created by Ivan Poderegin on 26.12.2023.
//

import Combine
import XCTest

@testable import Rutoken_Tech


final class CryptoManagerWithTokenTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: RtMockPkcs11HelperProtocol!
    var pcscHelper: RtMockPcscHelperProtocol!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!

    var tokensPublisher: CurrentValueSubject<[Pkcs11TokenProtocol], Never>!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = RtMockPkcs11HelperProtocol()
        pcscHelper = RtMockPcscHelperProtocol()
        openSslHelper = OpenSslHelperMock()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()

        tokensPublisher = CurrentValueSubject<[Pkcs11TokenProtocol], Never>([])
        pkcs11Helper.mocked_tokens = tokensPublisher.eraseToAnyPublisher()
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)
    }

    func testWithTokenUsbSuccess() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Token Login")
        let exp4 = XCTestExpectation(description: "Token Logout")
        let exp5 = XCTestExpectation(description: "CallBack")
        exp1.isInverted = true
        exp2.isInverted = true
        pcscHelper.mocked_startNfc_Void = {
            exp1.fulfill()
        }
        pcscHelper.mocked_stopNfc_Void = {
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
        tokensPublisher.send([token])

        await assertNoThrowAsync(try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "123456") { exp5.fulfill() })
        await fulfillment(of: [exp1, exp2, exp3, exp4, exp5], timeout: 0.3)
    }

    func testWithTokenNfcSuccess() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Token Login")
        let exp4 = XCTestExpectation(description: "Token Logout")
        let exp5 = XCTestExpectation(description: "CallBack")
        pcscHelper.mocked_startNfc_Void = {
            exp1.fulfill()
        }
        pcscHelper.mocked_stopNfc_Void = {
            exp2.fulfill()
        }
        pcscHelper.mocked_nfcExchangeIsStopped_AnyPublisherOf_VoidNever = {
            Just(Void()).eraseToAnyPublisher()
        }
        pcscHelper.mocked_getNfcCooldown_AsyncThrowingStreamOf_UIntError = {
            AsyncThrowingStream { con in
                con.finish()
            }
        }
        let token = TokenMock(serial: "12345678", currentInterface: .nfc)
        token.loginCallback = { pin in
            XCTAssertEqual(pin, "123456")
            exp3.fulfill()
        }
        token.logoutCallback = {
            exp4.fulfill()
        }
        tokensPublisher.send([token])

        await assertNoThrowAsync(try await manager.withToken(connectionType: .nfc, serial: token.serial, pin: "123456") { exp5.fulfill() })
        await fulfillment(of: [exp1, exp2, exp3, exp4, exp5], timeout: 0.3)
    }

    func testWithTokenNfcViaUsbSuccess() async {
        let exp1 = XCTestExpectation(description: "Start Nfc")
        let exp2 = XCTestExpectation(description: "Stop Nfc")
        let exp3 = XCTestExpectation(description: "Token Login")
        let exp4 = XCTestExpectation(description: "Token Logout")
        let exp5 = XCTestExpectation(description: "CallBack")
        exp1.isInverted = true
        exp2.isInverted = true
        pcscHelper.mocked_startNfc_Void = {
            exp1.fulfill()
        }
        pcscHelper.mocked_stopNfc_Void = {
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
        tokensPublisher.send([token])

        await assertNoThrowAsync(try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "123456") { exp5.fulfill() })
        await fulfillment(of: [exp1, exp2, exp3, exp4, exp5], timeout: 0.3)
    }

    func testWithTokenNoPinNoLoginLogoutSuccess() async {
        let exp1 = XCTestExpectation(description: "CallBack")
        let exp2 = XCTestExpectation(description: "Token Login")
        let exp3 = XCTestExpectation(description: "Token Logout")
        exp2.isInverted = true
        exp3.isInverted = true
        let token = TokenMock(serial: "12345678", currentInterface: .usb)
        token.loginCallback = { _ in
            exp2.fulfill()
        }
        token.logoutCallback = {
            exp3.fulfill()
        }
        tokensPublisher.send([token])

        await assertNoThrowAsync(try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) { exp1.fulfill() })
        await fulfillment(of: [exp1, exp2, exp3], timeout: 0.3)
    }

    func testWithTokenConnectionLostNfcError() async {
        pcscHelper.mocked_startNfc_Void = {}
        pcscHelper.mocked_stopNfc_Void = {}
        pcscHelper.mocked_nfcExchangeIsStopped_AnyPublisherOf_VoidNever = {
            Just(Void()).eraseToAnyPublisher()
        }
        pcscHelper.mocked_getNfcCooldown_AsyncThrowingStreamOf_UIntError = {
            AsyncThrowingStream { con in
                con.finish()
            }
        }

        let token = TokenMock(serial: "12345678", currentInterface: .nfc)
        tokensPublisher.send([token])

        token.loginCallback = { _ in
            throw Pkcs11Error.internalError(rv: 10)
        }
        pkcs11Helper.mocked_isPresent__SlotCK_SLOT_ID_Bool = { _ in
            return false
        }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .nfc, serial: "12345678", pin: "12345678") { },
            throws: CryptoManagerError.connectionLost)
    }

    func testWithTokenExchangeIsOverNfc() async {
        pcscHelper.mocked_startNfc_Void = {}
        pcscHelper.mocked_stopNfc_Void = {}
        pcscHelper.mocked_getNfcCooldown_AsyncThrowingStreamOf_UIntError = {
            AsyncThrowingStream { con in
                con.finish()
            }
        }
        pcscHelper.mocked_nfcExchangeIsStopped_AnyPublisherOf_VoidNever = {
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
        pcscHelper.mocked_startNfc_Void = {
            throw NfcError.cancelledByUser
        }
        pcscHelper.mocked_stopNfc_Void = {}
        pcscHelper.mocked_nfcExchangeIsStopped_AnyPublisherOf_VoidNever = {
            Just(Void()).eraseToAnyPublisher()
        }
        pcscHelper.mocked_getNfcCooldown_AsyncThrowingStreamOf_UIntError = {
            AsyncThrowingStream { con in
                con.finish()
            }
        }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .nfc, serial: nil, pin: nil) {},
            throws: CryptoManagerError.nfcStopped)
    }

    func testWithTokenIncorrectPinError() async {
        let exp = XCTestExpectation(description: "Token Logout")
        exp.isInverted = true

        let token = TokenMock(serial: "12345678", currentInterface: .usb)
        tokensPublisher.send([token])

        token.loginCallback = { _ in
            throw Pkcs11Error.incorrectPin
        }
        token.logoutCallback = {
            exp.fulfill()
        }

        let attempts: UInt = 2
        token.getPinAttemptsCallback = { attempts }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: "12345678", pin: "incorrectPin") {},
            throws: CryptoManagerError.incorrectPin(attempts))
        await fulfillment(of: [exp], timeout: 0.3)
    }

    func testWithTokenWrongTokenError() async {
        let token = TokenMock(serial: "12345678", currentInterface: .usb)
        tokensPublisher.send([token])

        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: "WrongSerial", pin: "123456") {},
            throws: CryptoManagerError.wrongToken)
    }

    func testWithTokenKeyNotFoundError() async {
        let token = TokenMock(serial: "12345678", currentInterface: .usb)
        token.loginCallback = { pin in
            XCTAssertEqual(pin, "123456")
        }
        pkcs11Helper.mocked_isPresent__SlotCK_SLOT_ID_Bool = { _ in true }
        tokensPublisher.send([token])

        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: token.serial, pin: "123456") {
                throw Pkcs11Error.internalError()
            },
            throws: CryptoManagerError.unknown)
    }

    func testWithTokenConnectionLostError() async {
        let token = TokenMock(serial: "12345678", currentInterface: .usb)
        tokensPublisher.send([token])

        token.loginCallback = { _ in
            throw Pkcs11Error.internalError(rv: 10)
        }
        pkcs11Helper.mocked_isPresent__SlotCK_SLOT_ID_Bool = { _ in return false }

        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: "12345678", pin: "12345678") { },
            throws: CryptoManagerError.connectionLost)
    }
}
