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
    var users: AnyPublisher<[Rutoken_Tech.BankUserInfo], Never> {
        usersPublisher.eraseToAnyPublisher()
    }

    var usersPublisher = CurrentValueSubject<[BankUserInfo], Never>([])

    func listUsers() -> [BankUserInfo] {
        usersPublisher.value
    }

    func deleteUser(user: BankUserInfo) throws {
        try deleteUserCallback(user)
    }

    var deleteUserCallback: (BankUserInfo) throws -> Void = { _ in }

    func createUser(fullname: String,
                    title: String,
                    expiryDate: Date,
                    keyId: String,
                    certHash: String,
                    tokenSerial: String) throws -> ManagedBankUser {
        try createUserCallback(fullname, title, expiryDate, keyId, certHash, tokenSerial)
    }

    var createUserCallback: (String, String, Date, String, String, String) throws -> ManagedBankUser = { _, _, _, _, _, _ in
        throw UserManagerError.general
    }

    func createUser(from cert: CertMetaData) throws -> ManagedBankUser {
        try createUserFromCertCallback(cert)
    }

    var createUserFromCertCallback: (CertMetaData) throws -> ManagedBankUser = { _ in throw UserManagerError.general }
}
