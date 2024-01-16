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

struct CsrModel {
    var subjects: [SubjectEntryTitle: String]
}

extension CsrModel {
    static func makeDefaultModel() -> CsrModel {
        .init(subjects: [
            .commonName: "Rutech Test Name",
            .email: "ivanova_ekaterina@rutoken.ru",
            .organizationName: "АО \"Актив Софт\"",
            .ogrn: "1037700094541",
            .organizationUnitName: "Аналитика",
            .title: "Руководитель отдела",
            .snils: "12345678900", // "123-456-789 00"
            .inn: "7729361030",
            .countryName: "RU",
            .stateOrProvinceName: "Москва",
            .localityName: "г. Москва",
            .streetAddress: "Шарикоподшипниковская ул, д. 1"
        ])
    }
}
