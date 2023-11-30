//
//  Pkcs11HelperMock.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 22.11.2023.
//

@testable import Rutoken_Tech


class Pkcs11HelperMock: Pkcs11HelperProtocol {
    func getToken(with type: ConnectionType) throws -> TokenProtocol {
        switch getTokenResult {
        case .success(let token):
            return token
        case .failure(let err):
            throw err
        }
    }

    var getTokenResult: Result<TokenProtocol, Error> = .failure(Pkcs11Error.tokenNotFound)
}
