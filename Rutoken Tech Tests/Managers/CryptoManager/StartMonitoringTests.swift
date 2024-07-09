//
//  StartMonitoringTests.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 12.02.2024.
//

import XCTest

@testable import Rutoken_Tech


class CryptoManagerStartMonitoringTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: FileSourceMock!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = FileSourceMock()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)
    }

    func testStartMonitoringSuccess() async throws {
        XCTAssertNoThrow(try manager.startMonitoring())
    }

    func testStartMonitoringFailed() async throws {
        pkcs11Helper.startMonitoringCallback = { throw Pkcs11Error.internalError() }
        assertError(try manager.startMonitoring(), throws: CryptoManagerError.unknown)
    }
}
