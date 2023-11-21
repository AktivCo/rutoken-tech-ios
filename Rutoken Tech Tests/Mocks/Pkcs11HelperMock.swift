//
//  Pkcs11HelperMock.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 22.11.2023.
//

@testable import Rutoken_Tech


class Pkcs11HelperMock: Pkcs11HelperProtocol {
    func getConnectedToken(tokenType: TokenInterface) throws -> TokenProtocol {
        try getConnectedTokenCallback(tokenType)
    }

    var getConnectedTokenCallback: (TokenInterface) throws -> TokenProtocol = { _ in
        return Token()
    }

}
