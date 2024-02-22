//
//  BankUser.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 19.02.2024.
//

import CoreData
import Foundation


@objc(BankUser)
public class BankUser: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<BankUser> {
        return NSFetchRequest<BankUser>(entityName: "BankUser")
    }

    @NSManaged public var expiryDate: Date
    @NSManaged public var fullname: String
    @NSManaged public var title: String
    @NSManaged public var certId: String
    @NSManaged public var tokenSerial: String
}
