//
//  TokenStateTests.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 28.05.2024.
//

import Combine
import XCTest

@testable import Rutoken_Tech


final class CryptoManageTokenStateTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: RtMockPkcs11HelperProtocol!
    var pcscHelper: RtMockPcscHelperProtocol!
    var openSslHelper: RtMockOpenSslHelperProtocol!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!
    var deviceInfo: RtMockDeviceInfoHelperProtocol!

    var nfcToken: RtMockPkcs11TokenProtocol!
    var usbToken: RtMockPkcs11TokenProtocol!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = RtMockPkcs11HelperProtocol()
        pcscHelper = RtMockPcscHelperProtocol()
        openSslHelper = RtMockOpenSslHelperProtocol()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()
        deviceInfo = RtMockDeviceInfoHelperProtocol()

        usbToken = RtMockPkcs11TokenProtocol()
        nfcToken = RtMockPkcs11TokenProtocol()
        usbToken.setup()
        nfcToken.setup()
        nfcToken.mocked_currentInterface = .nfc
        nfcToken.mocked_supportedInterfaces = [.nfc]

        pkcs11Helper.mocked_tokens = Just([usbToken, nfcToken]).eraseToAnyPublisher()
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource, deviceInfo: deviceInfo)
    }

    func testUsbStates() async throws {
        deviceInfo.mocked_isPhone = true
        let states = try await awaitPublisherUnwrapped(manager.tokenState.collect(2)) {
            try await manager.withToken(connectionType: .usb, serial: usbToken.serial, pin: nil) {}
        }
        XCTAssertEqual(states, [.inProgress(isVcr: false), .ready])
    }

    func testUsbStatesIpad() async throws {
        deviceInfo.mocked_isPhone = false
        let states = try await awaitPublisherUnwrapped(manager.tokenState.collect(2)) {
            try await manager.withToken(connectionType: .usb, serial: usbToken.serial, pin: nil) {}
        }
        XCTAssertEqual(states, [.inProgress(isVcr: false), .ready])
    }

    func testUsbStatesIgnoreNfcCooldown() async throws {
        deviceInfo.mocked_isPhone = true
        pcscHelper.mocked_getNfcCooldown_AsyncThrowingStreamOf_UIntError = {
            AsyncThrowingStream { con in
                con.yield(5)
                con.finish(throwing: CryptoManagerError.unknown)
            }
        }
        let states = try await awaitPublisherUnwrapped(manager.tokenState.collect(2)) {
            try await manager.withToken(connectionType: .usb, serial: usbToken.serial, pin: nil) {}
        }
        XCTAssertEqual(states, [.inProgress(isVcr: false), .ready])
    }

    func testUsbStatesIgnoreNfcCooldownIpad() async throws {
        deviceInfo.mocked_isPhone = false
        pcscHelper.mocked_getNfcCooldown_AsyncThrowingStreamOf_UIntError = {
            AsyncThrowingStream { con in
                con.yield(5)
                con.finish(throwing: CryptoManagerError.unknown)
            }
        }
        let states = try await awaitPublisherUnwrapped(manager.tokenState.collect(2)) {
            try await manager.withToken(connectionType: .usb, serial: usbToken.serial, pin: nil) {}
        }
        XCTAssertEqual(states, [.inProgress(isVcr: false), .ready])
    }

    func testNfcStates() async throws {
        deviceInfo.mocked_isPhone = true
        pcscHelper.mocked_startNfc_Void = {}
        pcscHelper.mocked_stopNfc_Void = {}
        pcscHelper.mocked_nfcExchangeIsStopped_AnyPublisherOf_VoidNever = {
            Just(Void()).eraseToAnyPublisher()
        }
        pcscHelper.mocked_getNfcCooldown_AsyncThrowingStreamOf_UIntError = {
            AsyncThrowingStream { con in
                con.yield(5)
                con.yield(2)
                con.yield(0)
                con.finish()
            }
        }
        let states = try await awaitPublisherUnwrapped(manager.tokenState.collect(4)) {
            try await manager.withToken(connectionType: .nfc, serial: nfcToken.serial, pin: nil) {}
        }
        XCTAssertEqual(states, [.inProgress(isVcr: false), .cooldown(5), .cooldown(2), .ready])
    }

    func testNfcStatesIpad() async throws {
        deviceInfo.mocked_isPhone = false
        pcscHelper.mocked_startNfc_Void = {}
        pcscHelper.mocked_stopNfc_Void = {}
        pcscHelper.mocked_getNfcCooldown_AsyncThrowingStreamOf_UIntError = {
            AsyncThrowingStream { con in
                con.yield(5)
                con.yield(2)
                con.yield(0)
                con.finish()
            }
        }
        pcscHelper.mocked_nfcExchangeIsStopped_AnyPublisherOf_VoidNever = {
            Just(Void()).eraseToAnyPublisher()
        }
        let states = try await awaitPublisherUnwrapped(manager.tokenState.collect(4)) {
            try await manager.withToken(connectionType: .nfc, serial: nfcToken.serial, pin: nil) {}
        }
        XCTAssertEqual(states, [.inProgress(isVcr: true), .cooldown(5), .cooldown(2), .ready])
    }

    func testNfcStatesNfcCooldownError() async throws {
        deviceInfo.mocked_isPhone = true
        pcscHelper.mocked_startNfc_Void = {}
        pcscHelper.mocked_stopNfc_Void = {}
        pcscHelper.mocked_getNfcCooldown_AsyncThrowingStreamOf_UIntError = {
            AsyncThrowingStream { con in
                con.yield(5)
                con.finish(throwing: CryptoManagerError.unknown)
            }
        }
        pcscHelper.mocked_nfcExchangeIsStopped_AnyPublisherOf_VoidNever = {
            Just(Void()).eraseToAnyPublisher()
        }
        let states = try await awaitPublisherUnwrapped(manager.tokenState.collect(3)) {
            try await manager.withToken(connectionType: .nfc, serial: nfcToken.serial, pin: nil) {}
        }
        XCTAssertEqual(states, [.inProgress(isVcr: false), .cooldown(5), .ready])
    }

    func testNfcStatesNfcCooldownErrorIpad() async throws {
        deviceInfo.mocked_isPhone = false
        pcscHelper.mocked_startNfc_Void = {}
        pcscHelper.mocked_stopNfc_Void = {}
        pcscHelper.mocked_getNfcCooldown_AsyncThrowingStreamOf_UIntError = {
            AsyncThrowingStream { con in
                con.yield(5)
                con.finish(throwing: CryptoManagerError.unknown)
            }
        }
        pcscHelper.mocked_nfcExchangeIsStopped_AnyPublisherOf_VoidNever = {
            Just(Void()).eraseToAnyPublisher()
        }
        let states = try await awaitPublisherUnwrapped(manager.tokenState.collect(3)) {
            try await manager.withToken(connectionType: .nfc, serial: nfcToken.serial, pin: nil) {}
        }
        XCTAssertEqual(states, [.inProgress(isVcr: true), .cooldown(5), .ready])
    }
}
