//
//  EnumerateCertsTests.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 22.02.2024.
//

import XCTest

@testable import Rutoken_Tech


class CryptoManagerEnumerateCertsTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: FileHelperMock!

    var token: TokenMock!
    var certModel: CertModel!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = FileHelperMock()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper)

        token = TokenMock(serial: "87654321", currentInterface: .usb, supportedInterfaces: [.usb])
        pkcs11Helper.tokenPublisher.send([token])

        certModel = CertModel(id: "some id",
                              tokenSerial: token.serial,
                              name: "Иванов Михаил Романович",
                              jobTitle: "Дизайнер",
                              companyName: "Рутокен",
                              keyAlgo: .gostR3410_2012_256,
                              expiryDate: "07.03.2024",
                              causeOfInvalid: nil)
    }

    func testEnumerateCertsSuccess() async throws {
        let certData = Data(repeating: 0x07, count: 10)
        token.enumerateCertsCallback = {
            XCTAssertNil($0)
            return [Pkcs11ObjectMock(id: self.certModel.id, body: certData)]
        }
        openSslHelper.parseCertCallback = { cert in
            XCTAssertEqual(cert, certData)
            return self.certModel
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            let result = try await manager.enumerateCerts()
            XCTAssertEqual([certModel], result)
        }
    }

    func testEnumerateCertsTokenNotFoundError() async {
        await assertErrorAsync(try await manager.enumerateCerts(),
                               throws: CryptoManagerError.tokenNotFound)
    }

    func testEnumerateCertsBadData() async throws {
        token.enumerateCertsCallback = {
            XCTAssertNil($0)
            return [Pkcs11ObjectMock(id: self.certModel.id, body: nil)]
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            let result = try await manager.enumerateCerts()
            XCTAssertEqual([], result)
        }
    }

    func testEnumerateCertsNoId() async throws {
        token.enumerateCertsCallback = {
            XCTAssertNil($0)
            return [Pkcs11ObjectMock(id: nil, body: Data(repeating: 0x07, count: 10))]
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            let result = try await manager.enumerateCerts()
            XCTAssertEqual([], result)
        }
    }

    func testEnumerateCertsParsingError() async throws {
        let error = OpenSslError.generalError(12, nil)

        token.enumerateCertsCallback = {
            XCTAssertNil($0)
            return [Pkcs11ObjectMock(id: self.certModel.id, body: Data(repeating: 0x07, count: 10))]
        }
        openSslHelper.parseCertCallback = { _ in
            throw error
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            await assertErrorAsync(try await manager.enumerateCerts(), throws: error)
        }
    }
}
