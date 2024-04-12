//
//  UserManagerMock.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 26.02.2024.
//

import Combine
import Foundation

@testable import Rutoken_Tech


class UserManagerMock: UserManagerProtocol {
    var users: AnyPublisher<[Rutoken_Tech.BankUser], Never> {
        usersPublisher.eraseToAnyPublisher()
    }

    var usersPublisher = CurrentValueSubject<[BankUser], Never>([])

    func listUsers() -> [BankUser] {
        usersPublisher.value
    }

    func deleteUser(user: BankUser) throws {
        try deleteUserCallback(user)
    }

    var deleteUserCallback: (BankUser) throws -> Void = { _ in  }

    func createUser(fullname: String, title: String, expiryDate: Date, keyId: String, certHash: String, tokenSerial: String) throws -> BankUser? {
        try createUserCallback(fullname, title, expiryDate, keyId, certHash, tokenSerial)
    }

    var createUserCallback: (String, String, Date, String, String, String) throws -> BankUser? = { _, _, _, _, _, _  in return nil }

    func createUser(from cert: CertViewData) throws -> BankUser? {
        try createUserFromCertCallback(cert)
    }

    var createUserFromCertCallback: (CertViewData) throws -> BankUser? = { _ in return nil }
}
