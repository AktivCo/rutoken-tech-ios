//
//  EnumerateCertsTests.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 22.02.2024.
//

import Combine
import XCTest

@testable import Rutoken_Tech


let unitTestCert = """
-----BEGIN CERTIFICATE-----
MIIFcjCCBR2gAwIBAgIJAPS1KxQfsVEKMAwGCCqFAwcBAQMCBQAwgeIxGDAWBgNV
BAMMD1J1dG9rZW4gVGVjaCBDQTEhMB8GCSqGSIb3DQEJARYScnV0b2tlbkBydXRv
a2VuLnJ1MSMwIQYDVQQKDBrQkNCeICLQkNC60YLQuNCyINCh0L7RhNGCIjELMAkG
A1UEBhMCUlUxGTAXBgNVBAgMENCzLiDQnNC+0YHQutCy0LAxFTATBgNVBAcMDNCc
0L7RgdC60LLQsDE/MD0GA1UECQw20KjQsNGA0LjQutC+0L/QvtC00YjQuNC/0L3Q
uNC60L7QstGB0LrQsNGPINGD0LssINC0LiA1MB4XDTI0MDQxNTA5MjE0N1oXDTI1
MDQxNTA5MjE0N1owggGEMSswKQYJKoZIhvcNAQkBFhxpdmFub3ZhX2VrYXRlcmlu
YUBydXRva2VuLnJ1MRgwFgYIKoUDA4EDAQESCjc3MjkzNjEwMzAxGTAXBgNVBAcM
ENCzLiDQnNC+0YHQutCy0LAxCzAJBgNVBAYTAlJVMRcwFQYDVQQDDA5Vbml0IHRl
c3QgY2VydDEYMBYGBSqFA2QBEg0xMDM3NzAwMDk0NTQxMRswGQYDVQQLDBLQkNC9
0LDQu9C40YLQuNC60LAxFTATBgNVBAgMDNCc0L7RgdC60LLQsDEuMCwGA1UEDAwl
0KDRg9C60L7QstC+0LTQuNGC0LXQu9GMINC+0YLQtNC10LvQsDEWMBQGBSqFA2QD
EgsxMjM0NTY3ODkwMDEjMCEGA1UECgwa0JDQniAi0JDQutGC0LjQsiDQodC+0YTR
giIxPzA9BgNVBAkMNtCo0LDRgNC40LrQvtC/0L7QtNGI0LjQv9C90LjQutC+0LLR
gdC60LDRjyDRg9C7LCDQtC4gMTBmMB8GCCqFAwcBAQEBMBMGByqFAwICIwIGCCqF
AwcBAQICA0MABECM0JFIANCsaf29X1Op54bbn50fH6OrHNXiRdJiJr1OeUYHaQOl
IhgninlLiNSURktKs60lKocoIsFl0IW7wyQ8o4ICBjCCAgIwZwYFKoUDZG8EXgxc
0KHRgNC10LTRgdGC0LLQviDRjdC70LXQutGC0YDQvtC90L3QvtC5INC/0L7QtNC/
0LjRgdC4OiDQodCa0JfQmCAi0KDRg9GC0L7QutC10L0g0K3QptCfIDMuMCIwCwYD
VR0PBAQDAgTwMB0GA1UdJQQWMBQGCCsGAQUFBwMCBggrBgEFBQcDBDAMBgUqhQNk
cgQDAgEAMBYGA1UdIAEB/wQMMAowCAYGKoUDZHEBMB0GA1UdDgQWBBTTgKbmPV80
rJE2UVjtEIWeicRU/TCCASQGA1UdIwSCARswggEXgBQfg+dirupA1bYJTzfeyHKD
82LUZaGB6KSB5TCB4jEYMBYGA1UEAwwPUnV0b2tlbiBUZWNoIENBMSEwHwYJKoZI
hvcNAQkBFhJydXRva2VuQHJ1dG9rZW4ucnUxIzAhBgNVBAoMGtCQ0J4gItCQ0LrR
gtC40LIg0KHQvtGE0YIiMQswCQYDVQQGEwJSVTEZMBcGA1UECAwQ0LMuINCc0L7R
gdC60LLQsDEVMBMGA1UEBwwM0JzQvtGB0LrQstCwMT8wPQYDVQQJDDbQqNCw0YDQ
uNC60L7Qv9C+0LTRiNC40L/QvdC40LrQvtCy0YHQutCw0Y8g0YPQuywg0LQuIDWC
FAI8x5mIdgpYFkKs8OG3cS4khY9pMAwGCCqFAwcBAQMCBQADQQA85TWXxQ2i+USp
2uWDReSNB34EaDTjkr8GqCS1SE1gITAhkA+6zKOwIitRzTd9CcEdx6yZted672gG
S4UdEY8f
-----END CERTIFICATE-----
"""

class CryptoManagerEnumerateCertsTests: XCTestCase {
    var manager: CryptoManager!
    var pkcs11Helper: RtMockPkcs11HelperProtocol!
    var pcscHelper: RtMockPcscHelperProtocol!
    var openSslHelper: RtMockOpenSslHelperProtocol!
    var fileHelper: RtMockFileHelperProtocol!
    var fileSource: RtMockFileSourceProtocol!

    var token: RtMockPkcs11TokenProtocol!
    var tokensPublisher: CurrentValueSubject<[Pkcs11TokenProtocol], Never>!
    var keyId: Data!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        pkcs11Helper = RtMockPkcs11HelperProtocol()
        pcscHelper = RtMockPcscHelperProtocol()
        openSslHelper = RtMockOpenSslHelperProtocol()
        fileHelper = RtMockFileHelperProtocol()
        fileSource = RtMockFileSourceProtocol()

        token = RtMockPkcs11TokenProtocol()
        token.setup()
        tokensPublisher = CurrentValueSubject<[Pkcs11TokenProtocol], Never>([token])
        pkcs11Helper.mocked_tokens = tokensPublisher.eraseToAnyPublisher()

        manager = CryptoManager(pkcs11Helper: pkcs11Helper, pcscHelper: pcscHelper,
                                openSslHelper: openSslHelper, fileHelper: fileHelper,
                                fileSource: fileSource)
        keyId = Data.random()
    }

    func testEnumerateCertsSuccess() async throws {
        token.mocked_enumerateCerts_ArrayOf_Pkcs11ObjectProtocol = {
            let object = RtMockPkcs11ObjectProtocol()
            object.mocked_getValue_forAttrAttrtypePkcs11DataAttribute_Data = { attr in
                switch attr {
                case .id: return self.keyId
                case .value: return Data(unitTestCert.utf8)
                default: throw Pkcs11Error.internalError(rv: 1)
                }
            }
            return [object]
        }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            let result = try await manager.enumerateCerts()
            XCTAssertEqual(result, [.init(keyId: keyId, tokenSerial: token.serial, from: Data(unitTestCert.utf8))!])
        }
    }

    func testEnumerateCertsSuccessZeroCerts() async throws {
        token.mocked_enumerateCerts_ArrayOf_Pkcs11ObjectProtocol = { [] }
        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            let result = try await manager.enumerateCerts()
            XCTAssertEqual(result, [])
        }
    }

    func testEnumerateCertsTokenNotFoundError() async {
        await assertErrorAsync(try await manager.enumerateCerts(),
                               throws: CryptoManagerError.tokenNotFound)
    }

    func testDecryptCmsConnectionLostError() async throws {
        token.mocked_enumerateCerts_ArrayOf_Pkcs11ObjectProtocol = {
            throw Pkcs11Error.internalError()
        }
        pkcs11Helper.mocked_isPresent__SlotCK_SLOT_ID_Bool = { _ in
            return false
        }
        await assertErrorAsync(
            try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
                _ = try await manager.enumerateCerts()
            },
            throws: CryptoManagerError.connectionLost)
    }

    func testEnumerateCertsGetValueThrowsError() async throws {
        let error = Pkcs11Error.internalError(rv: 1)
        token.mocked_enumerateCerts_ArrayOf_Pkcs11ObjectProtocol = {
            let object = RtMockPkcs11ObjectProtocol()
            object.mocked_getValue_forAttrAttrtypePkcs11DataAttribute_Data = { _ in
                throw error
            }
            return [object]
        }

        try await manager.withToken(connectionType: .usb, serial: token.serial, pin: nil) {
            await assertErrorAsync(try await manager.enumerateCerts(), throws: error)
        }
    }
}
