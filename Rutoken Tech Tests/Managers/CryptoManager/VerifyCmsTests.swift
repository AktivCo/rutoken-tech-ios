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
    var fileSource: FileSourceMock!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = FileHelperMock()
        fileSource = FileSourceMock()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)
    }

    func testVerifyCmsSuccess() async {
        let rootCaUrl = URL(fileURLWithPath: "some url")
        fileSource.getUrlResult = { file, dir in
            XCTAssertEqual(file, RtFile.rootCaCert.rawValue)
            XCTAssertEqual(dir, .credentials)
            return rootCaUrl
        }
        fileHelper.readFileCallback = { url in
            XCTAssertEqual(url, rootCaUrl)
            return Data()
        }
        await assertNoThrowAsync(try await manager.verifyCms(signedCms: Data(), document: Data()))
    }

    func testVerifyCmsGetUrlError() async {
        fileSource.getUrlResult = { _, _ in nil }
        await assertErrorAsync(try await manager.verifyCms(signedCms: Data(), document: Data()),
                               throws: CryptoManagerError.unknown)
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
