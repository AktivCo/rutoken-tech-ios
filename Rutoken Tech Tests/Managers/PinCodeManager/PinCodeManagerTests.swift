//
//  PinCodeManagerTests.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 01.03.2024.
//

import XCTest

@testable import Rutoken_Tech


class PinCodeManagerTests: XCTestCase {
    var manager: PinCodeManager!
    var keychainHelper: KeychainHelperMock!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        keychainHelper = KeychainHelperMock()
        manager = PinCodeManager(keychainManager: keychainHelper)
    }

    func testSaveWithBioSuccess() throws {
        let pin = "12345678"
        let serial = "qwerty1234"
        let exp = XCTestExpectation(description: "pin saved callback")
        keychainHelper.setCallback = { data, key, bio in
            XCTAssertEqual(pin, data as? String)
            XCTAssertEqual(serial, key)
            XCTAssertEqual(bio, .biometryOrPasscode)
            exp.fulfill()
            return true
        }

        manager.savePin(pin: pin, for: serial, withBio: true)
        wait(for: [exp], timeout: 0.3)
    }

    func testSaveWithoutBioSuccess() throws {
        let pin = "12345678"
        let serial = "qwerty1234"
        let exp = XCTestExpectation(description: "pin saved callback")
        keychainHelper.setCallback = { data, key, bio in
            XCTAssertEqual(pin, data as? String)
            XCTAssertEqual(serial, key)
            XCTAssertEqual(bio, .any)
            exp.fulfill()
            return true
        }

        manager.savePin(pin: pin, for: serial, withBio: false)
        wait(for: [exp], timeout: 0.3)
    }

    func testDeleteSuccess() {
        let serial = "qwerty1234"

        let exp = XCTestExpectation(description: "pin is deleted")
        keychainHelper.deleteCallback = { key in
            XCTAssertEqual(serial, key)
            exp.fulfill()
            return true
        }

        manager.deletePin(for: serial)
        wait(for: [exp], timeout: 0.3)
    }

    func testGetPinSuccess() throws {
        let tokenSerial = "qwerty1234"
        let pin = "12345678"
        keychainHelper.getCallback = { serial in
            XCTAssertEqual(serial, tokenSerial)
            return pin
        }
        XCTAssertEqual(pin, manager.getPin(for: tokenSerial))
    }
}
