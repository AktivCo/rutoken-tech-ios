//
//  AppAlert.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 06.12.2023.
//

import RtUiComponents


enum AppAlert {
    case certGenerated

    var alertModel: RtAlertModel {
        switch self {
        case .certGenerated:
            return .init(title: .titleOnly("Тестовый сертификат сгенерирован"),
                         buttons: [.init(.regular("ОК"))])
        }
    }
}
