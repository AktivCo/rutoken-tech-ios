//
//  UserManager.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 20.02.2024.
//

import Combine
import CoreData
import Foundation


enum UserManagerError: Error {
    case general
}

protocol UserManagerProtocol {
    var users: AnyPublisher<[BankUserInfo], Never> { get }
    func listUsers() -> [BankUserInfo]
    func deleteUser(user: BankUserInfo) throws
    func createUser(from cert: CertMetaData) throws -> ManagedBankUser
}

class UserManager: UserManagerProtocol {
    let context: NSManagedObjectContext
    var users: AnyPublisher<[BankUserInfo], Never> {
        usersPublisher.eraseToAnyPublisher()
    }

    private let usersPublisher = CurrentValueSubject<[BankUserInfo], Never>([])

    init() {
        let container = NSPersistentContainer(name: "AppStorage")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        self.context = container.viewContext
        updateUsers()
    }

    private func updateUsers() {
        usersPublisher.send(((try? context.fetch(ManagedBankUser.fetchRequest())) ?? []).map { $0.toBankUserInfo() })
    }

    func listUsers() -> [BankUserInfo] {
        return usersPublisher.value
    }

    func deleteUser(user: BankUserInfo) throws {
        guard let managedUser = ((try? context.fetch(ManagedBankUser.fetchRequest())) ?? []).first(where: { $0.certHash == user.certHash }) else {
            throw UserManagerError.general
        }
        context.delete(managedUser)
        try context.save()
        updateUsers()
    }

    func createUser(fullname: String,
                    title: String,
                    expiryDate: Date,
                    keyId: String,
                    certHash: String,
                    tokenSerial: String) throws -> ManagedBankUser {
        guard let entity = NSEntityDescription.entity(forEntityName: ManagedBankUser.entityName, in: context) else {
            throw UserManagerError.general
        }
        let newUser = ManagedBankUser(entity: entity, insertInto: context)
        newUser.expiryDate = expiryDate
        newUser.fullname = fullname
        newUser.title = title
        newUser.keyId = keyId
        newUser.certHash = certHash
        newUser.tokenSerial = tokenSerial
        try context.save()
        updateUsers()
        return newUser
    }

    func createUser(from cert: CertMetaData) throws -> ManagedBankUser {
        guard let entity = NSEntityDescription.entity(forEntityName: ManagedBankUser.entityName, in: context) else {
            throw UserManagerError.general
        }
        let newUser = ManagedBankUser(entity: entity, insertInto: context)
        newUser.certHash = cert.hash
        newUser.keyId = cert.keyId
        newUser.tokenSerial = cert.tokenSerial
        newUser.fullname = cert.name
        newUser.title = cert.jobTitle
        newUser.expiryDate = cert.expiryDate
        try context.save()
        updateUsers()
        return newUser
    }
}
