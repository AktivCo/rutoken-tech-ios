//
//  CertRequest.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 15.01.2024.
//

import Foundation


enum SubjectEntryTitle: String, CaseIterable {
    case commonName = "CN"
    case email = "emailAddress"
    case organizationName = "O"
    case ogrn = "OGRN"
    case organizationUnitName = "OU"
    case title = "title"
    case snils = "SNILS"
    case inn = "INN"
    case countryName = "C"
    case stateOrProvinceName = "ST"
    case localityName = "L"
    case streetAddress = "street"

    var fullName: String {
        switch self {
        case .commonName:
            return "Кому выдан"
        case .email:
            return "Электронная почта"
        case .organizationName:
            return "Организация"
        case .ogrn:
            return "ОГРН"
        case .organizationUnitName:
            return "Подразделение"
        case .title:
            return "Должность"
        case .snils:
            return "СНИЛС"
        case .inn:
            return "ИНН юридического лица"
        case .countryName:
            return "Страна"
        case .stateOrProvinceName:
            return "Регион"
        case .localityName:
            return "Населенный пункт"
        case .streetAddress:
            return "Адрес"
        }
    }
}

extension SubjectEntryTitle {
    var defaultValueForModel: String {
        switch self {
        case .commonName:
            return ""
        case .email:
            return "ivanova_ekaterina@rutoken.ru"
        case .organizationName:
            return "АО \"Актив Софт\""
        case .ogrn:
            return "1037700094541"
        case .organizationUnitName:
            return "Аналитика"
        case .title:
            return "Руководитель отдела"
        case .snils:
            return "123-456-789 00"
        case .inn:
            return "7729361030"
        case .countryName:
            return "Россия"
        case .stateOrProvinceName:
            return "Москва"
        case .localityName:
            return "г. Москва"
        case .streetAddress:
            return "Шарикоподшипниковская ул, д. 1"
        }
    }
}

struct CsrModel: Equatable {
    var subjects: [SubjectEntryTitle: String]
}

extension CsrModel {
    static func makeDefaultModel() -> CsrModel {
        var tmp: [SubjectEntryTitle: String] = [:]
        SubjectEntryTitle.allCases.forEach {
            switch $0 {
            case .snils:
                var snilsValue = $0.defaultValueForModel
                snilsValue.removeAll(where: { "- ".contains($0) })
                tmp[$0] = snilsValue
            case .countryName:
                tmp[$0] = "RU"
            default:
                tmp[$0] = $0.defaultValueForModel
            }
        }
        return CsrModel(subjects: tmp)
    }
}
