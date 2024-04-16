//
//  VerifyCmsTests.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 16.04.2024.
//

import XCTest

@testable import Rutoken_Tech


class CryptoManagerVerifyCmsTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: Pkcs11HelperMock!
    var pcscHelper: PcscHelperMock!
    var openSslHelper: OpenSslHelperMock!
    var fileHelper: FileHelperMock!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = FileHelperMock()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper)
    }

    func testVerifyCmsSuccess() async {
        await assertNoThrowAsync(try await manager.verifyCms(signedCms: Data(), document: Data()))
    }

    func testVerifyCmsFailedChain() async {
        openSslHelper.verifyCmsCallback = { .failedChain }
        await assertErrorAsync(try await manager.verifyCms(signedCms: Data(), document: Data()),
                               throws: CryptoManagerError.failedChain)
    }

    func testVerifyCmsError() async {
        openSslHelper.verifyCmsCallback = { .invalidSignature(.generalError(1, nil)) }
        await assertErrorAsync(try await manager.verifyCms(signedCms: Data(), document: Data()),
                               throws: CryptoManagerError.invalidSignature)
    }

    func testVerifyCmsAnyOtherError() async {
        fileHelper.readFileCallback = { _ in throw "some error" }
        await assertErrorAsync(try await manager.verifyCms(signedCms: Data(), document: Data()),
                               throws: CryptoManagerError.unknown)
    }
}
