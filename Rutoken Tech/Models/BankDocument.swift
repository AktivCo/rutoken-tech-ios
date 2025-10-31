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
    }

    enum SignStatus {
        case ok
        case brokenChain
        case invalid
    }

    let id = UUID()
    let name: String
    let action: ActionType
    let amount: Int
    let companyName: String
    let paymentTime: Date
    var inArchive: Bool = false
    var signStatus: SignStatus = .ok
    var dateOfChange: Date?

    static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy H:mm"
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
        case paymentTime
        case action
    }

    var direction: DocType {
        switch self.action {
        case .decrypt, .verify:
            return .income
        case .sign, .encrypt:
            return .outcome
        }
    }

    var urls: [URL] {
        switch (self.action, self.inArchive) {
        case (.encrypt, false), (.sign, false):
            guard let url = getUrl(dirType: .core, name: name) else {
                return []
            }
            return [url]
        case (.decrypt, false):
            guard let encryptedUrl = getUrl(dirType: .core, name: name + ".enc") else {
                return []
            }
            return [encryptedUrl]
        case (.verify, _):
            guard let docUrl = getUrl(dirType: .core, name: name),
                  let signUrl = getUrl(dirType: .core, name: name + ".sig") else {
                return []
            }
            return [docUrl, signUrl]
        case (.decrypt, true):
            guard let url = getUrl(dirType: .temp, name: name) else {
                return []
            }
            return [url]
        case (.encrypt, true):
            guard let encryptedUrl = getUrl(dirType: .temp, name: name + ".enc") else {
                return []
            }
            return [encryptedUrl]
        case (.sign, true):
            guard let docUrl = getUrl(dirType: .temp, name: name),
                  let signUrl = getUrl(dirType: .temp, name: name + ".sig") else {
                return []
            }
            return [docUrl, signUrl]
        }
    }

    private func getUrl(dirType: DocumentDir, name: String? = nil) -> URL? {
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        guard let name else {
            return documentsUrl.appendingPathComponent(dirType.rawValue)
        }
        return documentsUrl.appendingPathComponent(dirType.rawValue).appendingPathComponent(name)
    }
}

extension BankDocument: Equatable {
    static func == (lhs: BankDocument, rhs: BankDocument) -> Bool {
        lhs.name == rhs.name &&
        lhs.amount == rhs.amount &&
        lhs.companyName == rhs.companyName &&
        lhs.inArchive == rhs.inArchive &&
        lhs.signStatus == rhs.signStatus &&
        lhs.paymentTime.getString(as: dateFormatter.dateFormat) == rhs.paymentTime.getString(as: dateFormatter.dateFormat)
    }
}

enum DocType: String, RawRepresentable, CaseIterable {
    case outcome = "Исходящие"
    case income = "Входящие"
}
