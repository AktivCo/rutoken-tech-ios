//
//  TokenMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 05.12.2023.
//

@testable import Rutoken_Tech


class TokenMock: TokenProtocol {
    var slot: CK_SLOT_ID
    let label: String
    let serial: String
    let model: TokenModel
    let type: TokenType
    let connectionType: ConnectionType

    init(slot: CK_SLOT_ID = CK_SLOT_ID(), label: String = "", serial: String = "", model: TokenModel = .rutoken2,
         connectionType: ConnectionType = .nfc, type: TokenType = .usb) {
        self.slot = slot
        self.label = label
        self.serial = serial
        self.model = model
        self.type = type
        self.connectionType = connectionType
    }

    func getInfo() -> TokenInfo {
        .init(label: self.label, serial: self.serial, model: self.model, connectionType: self.connectionType, type: self.type)
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

    func deleteKeyPair(with id: String) throws {}

    func enumerateCerts() throws -> [Pkcs11Cert] { try enumerateCertsCallback() }

    var enumerateCertsCallback: () throws -> [Pkcs11Cert] = { [] }

    func enumerateKeys() throws -> [Pkcs11KeyPair] { try enumerateKeysCallback() }

    var enumerateKeysCallback: () throws -> [Pkcs11KeyPair] = { [] }
}
