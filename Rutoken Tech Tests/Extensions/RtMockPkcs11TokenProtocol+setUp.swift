//
//  RtMockPkcs11TokenProtocol+setUp.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 02.09.2024.
//

@testable import Rutoken_Tech


extension RtMockPkcs11TokenProtocol {
    func setup() {
        mocked_serial = "12345678"
        mocked_currentInterface = .usb
        mocked_supportedInterfaces = [.usb]
        mocked_slot = CK_SLOT_ID()
        mocked_label = "Rutoken"
        mocked_model = .rutoken3_3200
        mocked_login_withPinString_Void = { _ in }
        mocked_logout_Void = {}
        mocked_enumerateKey_byIdString_Pkcs11KeyPair = { _ in
            Pkcs11KeyPair(publicKey: Pkcs11ObjectMock(), privateKey: Pkcs11ObjectMock())
        }
        mocked_enumerateKeys_byAlgoPkcs11KeyAlgorithm_ArrayOf_Pkcs11KeyPair = { _ in
            return [Pkcs11KeyPair(publicKey: Pkcs11ObjectMock(),
                                  privateKey: Pkcs11ObjectMock())]
        }
        mocked_getWrappedKey_withIdString_WrappedPointerOf_OpaquePointer = { _ in
            return WrappedPointer<OpaquePointer>({
                OpaquePointer.init(bitPattern: 1)!
            }, { _ in})!
        }
        mocked_importCert__CertData_forIdString_Void = { _, _ in }
    }
}
