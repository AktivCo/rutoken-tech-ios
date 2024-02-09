//
//  LinkType.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 09.02.2024.
//

import Foundation


enum LinkType {
    case phone(String)
    case browser(String)

    var getUrl: URL? {
        switch self {
        case let .phone(phoneNumber):
            var copyNumber = phoneNumber
            copyNumber.removeAll(where: { "+-() ".contains($0) })
            guard copyNumber.isNumber else { return nil }
            return URL(string: "tel:+" + copyNumber)
        case let .browser(url):
            return URL(string: "https://\(url)")
        }
    }
}
