//
//  UserManager.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 20.02.2024.
//

import Combine
import CoreData
import Foundation


protocol UserManagerProtocol {
    var users: AnyPublisher<[BankUser], Never> { get }
    func deleteUser(user: BankUser) throws
    func createUser(fullname: String, title: String, expiryDate: Date, certId: String, tokenSerial: String) throws -> BankUser?
    func createUser(from cert: CertModel) throws -> BankUser?
}

class UserManager: UserManagerProtocol {
    let context: NSManagedObjectContext
    var users: AnyPublisher<[BankUser], Never> {
        usersPublisher.eraseToAnyPublisher()
    }

    private let usersPublisher = CurrentValueSubject<[BankUser], Never>([])

    init(inMemory: Bool = false) {
        let container = NSPersistentContainer(name: "AppStorage")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        self.context = container.viewContext
        updateUsers()
    }

    private func updateUsers() {
        usersPublisher.send((try? context.fetch(BankUser.fetchRequest())) ?? [])
    }

    func deleteUser(user: BankUser) throws {
        context.delete(user)
        try context.save()
        updateUsers()
    }

    func createUser(fullname: String, title: String, expiryDate: Date, certId: String, tokenSerial: String) throws -> BankUser? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BankUser", in: context) else {
            return nil
        }
        let newUser = BankUser(entity: entity, insertInto: context)
        newUser.expiryDate = expiryDate
        newUser.fullname = fullname
        newUser.title = title
        newUser.certId = certId
        newUser.tokenSerial = tokenSerial
        try context.save()
        updateUsers()
        return newUser
    }

    func createUser(from cert: CertModel) throws -> BankUser? {
        guard let entity = NSEntityDescription.entity(forEntityName: "BankUser", in: context) else {
            return nil
        }
        guard let date = cert.expiryDate.getDate(with: "dd.MM.yyyy"),
              let certId = cert.id,
              let tokenSerial = cert.tokenSerial else {
            return nil
        }
        let newUser = BankUser(entity: entity, insertInto: context)
        newUser.expiryDate = date
        newUser.fullname = cert.name
        newUser.title = cert.jobTitle
        newUser.certId = certId
        newUser.tokenSerial = tokenSerial
        try context.save()
        updateUsers()
        return newUser
    }
}
