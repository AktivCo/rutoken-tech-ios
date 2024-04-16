//
//  ManagedBankUser.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 19.02.2024.
//

import CoreData
import Foundation


@objc(BankUser)
public class ManagedBankUser: NSManagedObject {
    static let entityName = "BankUser"

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedBankUser> {
        return NSFetchRequest<ManagedBankUser>(entityName: entityName)
    }

    @NSManaged public var expiryDate: Date
    @NSManaged public var fullname: String
    @NSManaged public var title: String
    @NSManaged public var keyId: String
    @NSManaged public var certHash: String
    @NSManaged public var tokenSerial: String

    func toBankUserInfo() -> BankUserInfo {
        BankUserInfo(expiryDate: expiryDate,
                     fullname: fullname,
                     title: title,
                     keyId: keyId,
                     certHash: certHash,
                     tokenSerial: tokenSerial)
    }
}
