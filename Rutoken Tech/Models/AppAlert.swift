//
//  AppAlert.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 06.12.2023.
//

import RtUiComponents


enum AppAlert {
    // MARK: Success
    case certGenerated
    case keyGenerated
    case documentSigned
    // MARK: Errors
    case unknownDevice
    case connectionLost
    case wrongToken
    case tokenNotFound
    case noCerts
    case noSuitCert
    case verifySuccess
    case failedChain
    case invalidSignature
    case unknownError

    var alertModel: RtAlertModel {
        switch self {
        case .certGenerated:
            return .init(title: .titleOnly("Тестовый сертификат сгенерирован"),
                         buttons: [.init(.regular("ОК"))])
        case .keyGenerated:
            return .init(title: .titleOnly("Ключевая пара сгенерирована"),
                         buttons: [.init(.regular("ОК"))])
        case .documentSigned:
            return .init(title: .titleOnly("Документ подписан"),
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
        case .noCerts:
            return .init(title: .titleOnly("На Рутокене нет сертификатов"),
                         buttons: [.init(.regular("ОК"))])
        case .noSuitCert:
            return .init(title: .titleOnly("На Рутокене нет подходящего сертификата"),
                         buttons: [.init(.regular("ОК"))])
        case .verifySuccess:
            return .init(title: .success("Подпись верна"),
                         buttons: [.init(.regular("OK"))])
        case .invalidSignature:
            return .init(title: .failure("Подпись неверна"),
                         buttons: [.init(.regular("OK"))])
        case .failedChain:
            return .init(title: .success("Подпись верна"), subTitle: "Но не удалось построить цепочку доверия для сертификата",
                         buttons: [.init(.regular("OK"))])
        case .unknownError:
            return .init(title: .titleOnly("Неизвестная ошибка"),
                         subTitle: "Попробуйте еще раз или обратитесь в Техническую поддержку",
                         buttons: [.init(.regular("ОК"))])
        }
    }

    init(from error: CryptoManagerError) {
        switch error {
        case .unknown, .incorrectPin, .nfcStopped:
            self = .unknownError
        case .connectionLost:
            self = .connectionLost
        case .tokenNotFound:
            self = .tokenNotFound
        case .wrongToken:
            self = .wrongToken
        case .noSuitCert:
            self = .noSuitCert
        case .failedChain:
            self = .failedChain
        case .invalidSignature:
            self = .invalidSignature
        }
    }
}
