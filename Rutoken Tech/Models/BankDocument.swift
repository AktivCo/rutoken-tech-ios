//
//  BankDocument.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 11.03.2024.
//

import Foundation


struct BankDocument: Codable {
    let name: String
    let amount: Int
    let companyName: String
    let paymentDay: Date
    var inArchive: Bool = false

    static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        return dateFormatter
    }

    static var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        return encoder
    }

    static var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }

    enum CodingKeys: CodingKey {
        case name
        case amount
        case companyName
        case paymentDay
    }
}

extension BankDocument: Equatable {
    static func == (lhs: BankDocument, rhs: BankDocument) -> Bool {
        lhs.name == rhs.name &&
        lhs.amount == rhs.amount &&
        lhs.companyName == rhs.companyName &&
        lhs.inArchive == rhs.inArchive &&
        lhs.paymentDay.getString(with: dateFormatter.dateFormat) == rhs.paymentDay.getString(with: dateFormatter.dateFormat)
    }
}
