//
//  TokenMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 05.12.2023.
//

@testable import Rutoken_Tech


class TokenMock: TokenProtocol {
    let label: String
    let serial: String
    let model: TokenModel
    let type: TokenType
    let connectionType: ConnectionType

    init(label: String = "", serial: String = "", model: TokenModel = .rutoken2,
         connectionType: ConnectionType = .nfc, type: TokenType = .usb) {
        self.label = label
        self.serial = serial
        self.model = model
        self.type = type
        self.connectionType = connectionType
    }

    func getInfo() -> TokenInfo {
        .init(label: self.label, serial: self.serial, model: self.model, connectionType: self.connectionType, type: self.type)
    }
}
