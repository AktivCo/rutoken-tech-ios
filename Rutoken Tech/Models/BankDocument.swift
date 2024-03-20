//
//  BankDocument.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 11.03.2024.
//

import Foundation


struct BankDocument: Codable, Identifiable {
    enum ActionType: String, Codable {
        case encrypt
        case decrypt
        case sign
        case verify
        case none
    }

    let id = UUID()
    let name: String
    var action: ActionType = .none
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

    var direction: DocType {
        switch self.action {
        case .decrypt, .verify, .none:
            return .income
        case .sign, .encrypt:
            return .outcome
        }
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

enum DocType: String, RawRepresentable, CaseIterable {
    case income = "Входящие"
    case outcome = "Исходящие"
}

extension BankDocument.ActionType {
    var getImageName: String {
        switch self {
        case .verify, .none:
            return "doc.text.fill"
        case .encrypt:
            return "lock.fill"
        case .sign:
            return "pencil"
        case .decrypt:
            return "doc.plaintext.fill"
        }
    }
}
