//
//  TokenMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 05.12.2023.
//

import Foundation

@testable import Rutoken_Tech


class TokenMock: Pkcs11TokenProtocol {
    let slot: CK_SLOT_ID
    let label: String
    let serial: String
    let model: Pkcs11TokenModel
    let currentInterface: Pkcs11TokenInterface
    let supportedInterfaces: Set<Pkcs11TokenInterface>

    init(slot: CK_SLOT_ID = CK_SLOT_ID(),
         label: String = "",
         serial: String = "",
         model: Pkcs11TokenModel = .rutoken3Nfc_3100,
         currentInterface: Pkcs11TokenInterface = .nfc,
         supportedInterfaces: Set<Pkcs11TokenInterface> = [.nfc]) {
        self.slot = slot
        self.label = label
        self.serial = serial
        self.model = model
        self.currentInterface = currentInterface
        self.supportedInterfaces = supportedInterfaces
    }

    func login(with pin: String) throws {
        try loginCallback(pin)
    }

    var loginCallback: (String) throws -> Void = { _ in }

    func logout() {
        logoutCallback()
    }

    var logoutCallback: () -> Void = { }

    func generateKeyPair(with id: String) throws {
        try generateKeyPairCallback(id)
    }

    var generateKeyPairCallback: (String) throws -> Void = { _ in }

    func enumerateCerts() throws -> [Pkcs11ObjectProtocol] { try enumerateCertsCallback() }
    func enumerateCerts(by id: String) throws -> [Pkcs11ObjectProtocol] { try enumerateCertsWithIdCallback(id) }

    var enumerateCertsCallback: () throws -> [Pkcs11ObjectProtocol] = { [] }
    var enumerateCertsWithIdCallback: (_ id: String) throws -> [Pkcs11ObjectProtocol] = { _ in [] }

    func enumerateKey(by id: String) throws -> Pkcs11KeyPair { try enumerateKeyWithIdCallback(id) }
    func enumerateKeys(by algo: Pkcs11KeyAlgorithm) throws -> [Pkcs11KeyPair] { try enumerateKeysWithAlgoCallback(algo) }

    var enumerateKeyWithIdCallback: (String) throws -> Pkcs11KeyPair = { _ in Pkcs11KeyPair(publicKey: Pkcs11ObjectMock(),
                                                                                             privateKey: Pkcs11ObjectMock()) }
    var enumerateKeysWithAlgoCallback: (Pkcs11KeyAlgorithm) throws -> [Pkcs11KeyPair] = { _ in [] }

    func getWrappedKey(with id: String) throws -> WrappedPointer<OpaquePointer> {
        try getWrappedKeyCallback(id)
    }

    var getWrappedKeyCallback: (String) throws -> WrappedPointer = { _ in
        WrappedPointer<OpaquePointer>({
            OpaquePointer.init(bitPattern: 1)!
        }, { _ in})!
    }

    func importCert(_ cert: Data, for id: String) throws {
        try importCertCallback(cert, id)
    }

    var importCertCallback: (Data, String) throws -> Void = { _, _ in }

    func deleteCert(with id: String) throws {
        try deleteCertCallback(id)
    }

    var deleteCertCallback: (String) throws -> Void = { _ in }

    func getPinAttempts() throws -> UInt {
        try getPinAttemptsCallback()
    }

    var getPinAttemptsCallback: () throws -> UInt = { 0 }
}
