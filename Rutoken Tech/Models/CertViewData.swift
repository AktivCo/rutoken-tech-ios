//
//  CertViewData.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 12.04.2024.
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
        case .notStartedBefore(let date): return "Сертификат начнет действовать \(date.getString(as: "dd.MM.YYYY"))"
        }
    }
}

struct CertViewData: Identifiable {
    let id: String

    let certInfo: CertMetaData
    let causeOfInvalid: CertInvalidReason?
    init(from cert: CertMetaData, reason: CertInvalidReason? = nil) {
        self.certInfo = cert
        self.id = cert.hash
        self.causeOfInvalid = reason
    }

#if DEBUG
    init(name: String = "Иванов Михаил Романович",
         jobTitle: String = "Дизайнер",
         companyName: String = "Рутокен",
         expiryDate: Date = Date(),
         reason: CertInvalidReason? = nil,
         body: Data = Data()) {
        self.certInfo = CertMetaData(keyId: "", tokenSerial: "12345678", hash: "qwerty123",
                                             name: name, jobTitle: jobTitle, companyName: companyName,
                                             startDate: Date(), expiryDate: Date())
        self.causeOfInvalid = reason
        self.id = UUID().uuidString
    }
#endif
}
