//
//  Pkcs11Helper.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//


protocol Pkcs11HelperProtocol {
    func getConnectedToken(tokenType: TokenInterface) throws -> TokenProtocol
}

enum Pkcs11Error: Error {
    case unknownError
    case connectionLost
    case tokenNotFound
}

class Pkcs11Helper: Pkcs11HelperProtocol {
    func getConnectedToken(tokenType: TokenInterface) throws -> TokenProtocol {
        return Token()
    }
}
