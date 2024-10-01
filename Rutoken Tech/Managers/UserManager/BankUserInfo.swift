//
//  BankUserInfo.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2024-04-17.
//

import Foundation

import RtUiComponents


struct BankUserInfo: RtListItem {
    let id = UUID().uuidString
    let expiryDate: Date
    let fullname: String
    let title: String?
    let keyId: Data
    let certHash: String
    let tokenSerial: String

    var state: RtListItemState {
        expiryDate < Date() ? .disableTap : .normal
    }
}
