//
//  Token.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//


protocol TokenProtocol {
    func getTokenInfo() throws -> TokenInfo
}

class Token: TokenProtocol {
    func getTokenInfo() throws -> TokenInfo {
        return TokenInfo(label: "", serial: "", model: .rutoken3Nfc, supportedInterfaces: [.usb])
    }
}
