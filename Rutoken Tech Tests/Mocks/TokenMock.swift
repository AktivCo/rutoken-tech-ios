//
//  TokenMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 05.12.2023.
//

import Foundation

@testable import Rutoken_Tech


class TokenMock: TokenProtocol {
    let label: String
    let serial: String
    let model: TokenModel
    let currentInterface: TokenInterface
    let supportedInterfaces: Set<TokenInterface>

    init(label: String = "",
         serial: String = "",
         model: TokenModel = .rutoken2,
         currentInterface: TokenInterface = .nfc,
         supportedInterfaces: Set<TokenInterface> = [.nfc]) {
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

    func enumerateCerts(by id: String?) throws -> [Pkcs11ObjectProtocol] { try enumerateCertsCallback(id) }

    var enumerateCertsCallback: (_ id: String?) throws -> [Pkcs11ObjectProtocol] = { _ in [] }

    func enumerateKeys(by id: String?, with type: KeyAlgorithm?) throws -> [Pkcs11KeyPair] { try enumerateKeysCallback(id, type) }

    var enumerateKeysCallback: (String?, KeyAlgorithm?) throws -> [Pkcs11KeyPair] = { _, _ in [] }

    func getWrappedKey(with id: String) throws -> WrappedPointer<OpaquePointer> {
        try getWrappedKeyCallback(id)
    }

    var getWrappedKeyCallback: (String) throws -> WrappedPointer = { _ in WrappedPointer(ptr: OpaquePointer.init(bitPattern: 1)!, {_ in})}

    func importCert(_ cert: Data, for id: String) throws {
        try importCertCallback(cert, id)
    }

    var importCertCallback: (Data, String) throws -> Void = { _, _ in }
}
