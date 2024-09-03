//
//  VerifyCmsTests.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 16.04.2024.
//

import Combine
import XCTest

@testable import Rutoken_Tech


class CryptoManagerVerifyCmsTests: XCTestCase {
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

    func testVerifyCmsSuccess() async {
        let rootCaUrl = URL(fileURLWithPath: "some url")
        let signedCms = "signed cms"
        let content = "content".data(using: .utf8)!
        let root = "some cert".data(using: .utf8)!

        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { file, dir in
            XCTAssertEqual(file, RtFile.rootCaCert.rawValue)
            XCTAssertEqual(dir, .credentials)
            return rootCaUrl
        }
        fileHelper.mocked_readFile_fromUrlURL_Data = { url in
            XCTAssertEqual(url, rootCaUrl)
            return root
        }
        openSslHelper.mocked_verifyCms_signedCmsString_forContentData_trustedRootsArrayOf_Data_VerifyCmsResult = { cms, data, certs in
            XCTAssertEqual(cms, signedCms)
            XCTAssertEqual(data, content)
            XCTAssertEqual(certs, [root])
            return .success
        }
        await assertNoThrowAsync(try await manager.verifyCms(signedCms: signedCms.data(using: .utf8)!, document: content))
    }

    func testVerifyCmsGetUrlError() async {
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in nil }
        await assertErrorAsync(try await manager.verifyCms(signedCms: Data(), document: Data()),
                               throws: CryptoManagerError.unknown)
    }

    func testVerifyCmsReadFileError() async {
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in throw "some error" }
        await assertErrorAsync(try await manager.verifyCms(signedCms: Data(), document: Data()),
                               throws: CryptoManagerError.unknown)
    }

    func testVerifyCmsFailedChain() async {
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }
        openSslHelper.mocked_verifyCms_signedCmsString_forContentData_trustedRootsArrayOf_Data_VerifyCmsResult = { _, _, _ in
            .failedChain
        }
        await assertErrorAsync(try await manager.verifyCms(signedCms: Data(), document: Data()),
                               throws: CryptoManagerError.failedChain)
    }

    func testVerifyCmsError() async {
        fileSource.mocked_getUrl_forFilenameString_inSourcedirSourceDir_URLOptional = { _, _ in URL(filePath: "") }
        fileHelper.mocked_readFile_fromUrlURL_Data = { _ in Data() }
        openSslHelper.mocked_verifyCms_signedCmsString_forContentData_trustedRootsArrayOf_Data_VerifyCmsResult = { _, _, _ in
            .invalidSignature(.generalError(1, nil))
        }
        await assertErrorAsync(try await manager.verifyCms(signedCms: Data(), document: Data()),
                               throws: CryptoManagerError.invalidSignature)
    }
}
