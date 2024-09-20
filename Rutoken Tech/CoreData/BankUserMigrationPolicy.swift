//
//  BankUserMigrationPolicy.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 20.09.2024.
//

import CoreData


final class BankUserMigrationPolicy: NSEntityMigrationPolicy {
    @objc func migrateKeyId(_ keyId: String) -> Data {
        return Data(keyId.utf8)
    }
}
