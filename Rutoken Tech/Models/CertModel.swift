//
//  CertModel.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 19.02.2024.
//

import Foundation


enum CertInvalidReason {
    case alreadyExist
    case expired
    case noKeyPair
    case notStartedBefore(Date)

    var rawValue: String {
        switch self {
        case .alreadyExist: return "Пользователь с таким сертификатом уже добавлен"
        case .expired: return "Сертификат истек"
        case .noKeyPair: return "Работа с сертификатом без ключевой пары в приложении невозможна"
        case .notStartedBefore(let date): return "Сертификат начнет действовать \(date.getString(with: "dd.MM.YYYY"))"
        }
    }
}

struct CertModel: Identifiable, Equatable {
    var id: String {
        return hash
    }

    var keyId: String?
    var hash: String
    var tokenSerial: String?

    let name: String
    let jobTitle: String
    let companyName: String
    let keyAlgo: KeyAlgorithm
    let expiryDate: String

    var causeOfInvalid: CertInvalidReason?

    static func == (lhs: CertModel, rhs: CertModel) -> Bool {
        return lhs.keyId == rhs.keyId &&
        lhs.hash == rhs.hash &&
        lhs.tokenSerial == rhs.tokenSerial &&
        lhs.name == rhs.name &&
        lhs.jobTitle == rhs.jobTitle &&
        lhs.companyName == rhs.companyName &&
        lhs.expiryDate == rhs.expiryDate
    }
}
