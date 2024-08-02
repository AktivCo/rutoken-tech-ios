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
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = Pkcs11HelperMock()
        pcscHelper = PcscHelperMock()
        openSslHelper = OpenSslHelperMock()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)
    }

    func testVerifyCmsSuccess() async {
        let rootCaUrl = URL(fileURLWithPath: "some url")
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { file, dir in
            XCTAssertEqual(file, RtFile.rootCaCert.rawValue)
            XCTAssertEqual(dir, .credentials)
            return rootCaUrl
        }
        fileHelper.mocked_readFile_fromUrlURL_Data = { url in
            XCTAssertEqual(url, rootCaUrl)
            return Data()
        }
        await assertNoThrowAsync(try await manager.verifyCms(signedCms: Data(), document: Data()))
    }

    func testVerifyCmsGetUrlError() async {
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in nil }
        await assertErrorAsync(try await manager.verifyCms(signedCms: Data(), document: Data()),
                               throws: CryptoManagerError.unknown)
    }

    func testVerifyCmsFailedChain() async {
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }
        openSslHelper.verifyCmsCallback = { .failedChain }
        await assertErrorAsync(try await manager.verifyCms(signedCms: Data(), document: Data()),
                               throws: CryptoManagerError.failedChain)
    }

    func testVerifyCmsError() async {
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }
        openSslHelper.verifyCmsCallback = { .invalidSignature(.generalError(1, nil)) }
        await assertErrorAsync(try await manager.verifyCms(signedCms: Data(), document: Data()),
                               throws: CryptoManagerError.invalidSignature)
    }

    func testVerifyCmsAnyOtherError() async {
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in throw "some error" }
        await assertErrorAsync(try await manager.verifyCms(signedCms: Data(), document: Data()),
                               throws: CryptoManagerError.unknown)
    }
}
