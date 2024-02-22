//
//  UserManager.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 20.02.2024.
//

import CoreData
import Foundation


protocol UserManagerProtocol {
    func getAllUsers() throws -> [BankUser]
    func deleteUser(user: BankUser) throws
    func createUser(fullname: String, title: String, expiryDate: Date, certId: String, tokenSerial: String) throws -> BankUser?
    func createUser(from cert: CertModel) throws -> BankUser?
}

class UserManager: UserManagerProtocol {
    let context: NSManagedObjectContext
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
    }

    func getAllUsers() throws -> [BankUser] {
        return try context.fetch(BankUser.fetchRequest())
    }

    func deleteUser(user: BankUser) throws {
        context.delete(user)
        try context.save()
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
        return newUser
    }
}
