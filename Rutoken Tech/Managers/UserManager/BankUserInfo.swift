//
//  BankUserInfo.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2024-04-17.
//

import Foundation


struct BankUserInfo: Identifiable {
    let id = UUID().uuidString
    let expiryDate: Date
    let fullname: String
    let title: String
    let keyId: String
    let certHash: String
    let tokenSerial: String
}
