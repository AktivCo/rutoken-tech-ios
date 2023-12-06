//
//  AppAlert.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 06.12.2023.
//

import RtUiComponents


enum AppAlert {
    case certGenerated
    case keyGenerated
    case unknownDevice
    case connectionLost
    case wrongToken
    case tokenNotFound
    case unknownError

    var alertModel: RtAlertModel {
        switch self {
        case .certGenerated:
            return .init(title: .titleOnly("Тестовый сертификат сгенерирован"),
                         buttons: [.init(.regular("ОК"))])
        case .keyGenerated:
            return .init(title: .titleOnly("Ключевая пара сгенерирована"),
                         buttons: [.init(.regular("ОК"))])
        case .unknownDevice:
            return .init(title: .titleOnly("Устройство не распознано"),
                         subTitle: "Приложите поддерживаемый Рутокен",
                         buttons: [.init(.regular("ОК"))])
        case .connectionLost:
            return .init(title: .titleOnly("Потеряно соединение с Рутокеном"),
                         subTitle: "Повторите подключение и не убирайте Рутокен до завершения обмена данными",
                         buttons: [.init(.regular("ОК"))])
        case .wrongToken:
            return .init(title: .titleOnly("Неподходящий Рутокен"),
                         subTitle: "Приложите Рутокен, который использовали при входе",
                         buttons: [.init(.regular("ОК"))])
        case .tokenNotFound:
            return .init(title: .titleOnly("Рутокен не обнаружен"),
                         subTitle: "Убедитесь, что Рутокен подключен к мобильному устройству",
                         buttons: [.init(.regular("ОК"))])
        case .unknownError:
            return .init(title: .titleOnly("Неизвестная ошибка"),
                         subTitle: "Попробуйте еще раз или обратитесь в Техническую поддержку",
                         buttons: [.init(.regular("ОК"))])
        }
    }
}
