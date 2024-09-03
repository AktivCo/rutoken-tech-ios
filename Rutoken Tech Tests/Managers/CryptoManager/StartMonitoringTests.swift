//
//  StartMonitoringTests.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 12.02.2024.
//

import Combine
import XCTest

@testable import Rutoken_Tech


class CryptoManagerStartMonitoringTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: RtMockPkcs11HelperProtocol!
    var pcscHelper: RtMockPcscHelperProtocol!
    var openSslHelper: RtMockOpenSslHelperProtocol!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = RtMockPkcs11HelperProtocol()
        pcscHelper = RtMockPcscHelperProtocol()
        openSslHelper = RtMockOpenSslHelperProtocol()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()

        pkcs11Helper.mocked_tokens = Just([]).eraseToAnyPublisher()
        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)
    }

    func testStartMonitoringSuccess() async throws {
        pkcs11Helper.mocked_startMonitoring_Void = {}
        XCTAssertNoThrow(try manager.startMonitoring())
    }

    func testStartMonitoringFailed() async throws {
        pkcs11Helper.mocked_startMonitoring_Void = { throw Pkcs11Error.internalError() }
        assertError(try manager.startMonitoring(), throws: CryptoManagerError.unknown)
    }
}
