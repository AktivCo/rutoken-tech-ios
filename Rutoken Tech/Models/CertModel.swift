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
    case invalidAlgo
    case notStartedBefore(String)

    var rawValue: String {
        switch self {
        case .alreadyExist: return "Пользователь с таким сертификатом уже добавлен"
        case .expired: return "Сертификат истек"
        case .noKeyPair: return "Работа с сертификатом без ключевой пары в приложении невозможна"
        case .invalidAlgo: return "Данный алгоритм не поддерживается приложением"
        case .notStartedBefore(let date): return "Сертификат начнет действовать \(date)"
        }
    }
}

struct CertModel: Identifiable, Equatable {
    var id: String
    var tokenSerial: String?

    let name: String
    let jobTitle: String
    let companyName: String
    let keyAlgo: KeyAlgorithm
    let expiryDate: String

    let causeOfInvalid: CertInvalidReason?

    static func == (lhs: CertModel, rhs: CertModel) -> Bool {
        return lhs.id == rhs.id &&
        lhs.tokenSerial == rhs.tokenSerial &&
        lhs.name == rhs.name &&
        lhs.jobTitle == rhs.jobTitle &&
        lhs.companyName == rhs.companyName &&
        lhs.expiryDate == rhs.expiryDate
    }
}
