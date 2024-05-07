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

    let keyId: String
    let tokenSerial: String

    let name: String
    let jobTitle: String
    let companyName: String
    let keyAlgo: KeyAlgorithm
    let expiryDate: String
    let causeOfInvalid: CertInvalidReason?

    init(from cert: CertMetaData, reason: CertInvalidReason? = nil) {
        self.id = cert.hash

        self.keyId = cert.keyId
        self.tokenSerial = cert.tokenSerial

        // displayed fields
        self.name = cert.name
        self.jobTitle = cert.jobTitle
        self.companyName = cert.companyName
        self.keyAlgo = cert.keyAlgo
        self.expiryDate = cert.expiryDate.getString(as: "dd.MM.YYYY")
        self.causeOfInvalid = reason
    }

#if DEBUG
    init(name: String = "Иванов Михаил Романович",
         jobTitle: String = "Дизайнер",
         companyName: String = "Рутокен",
         expiryDate: Date = Date(),
         reason: CertInvalidReason? = nil) {
        self.id = UUID().uuidString
        self.keyId = ""
        self.tokenSerial = ""

        self.name = name
        self.jobTitle = jobTitle
        self.companyName = companyName
        self.keyAlgo = .gostR3410_2012_256
        self.expiryDate = expiryDate.getString(as: "dd.MM.YYYY")
        self.causeOfInvalid = reason
    }
#endif
}
