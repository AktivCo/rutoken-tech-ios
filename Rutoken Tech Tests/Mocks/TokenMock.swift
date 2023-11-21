//
//  TokenMock.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 22.11.2023.
//

@testable import Rutoken_Tech


class TokenMock: TokenProtocol {
    func getTokenInfo() throws -> TokenInfo {
        try getTokenInfoCallback()
    }

    var getTokenInfoCallback: () throws -> TokenInfo = {
        TokenInfo(label: "test", serial: "1234", model: .rutoken3, supportedInterfaces: [.usb])
    }
}
