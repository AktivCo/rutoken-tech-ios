//
//  RtAppTab.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 26.10.2023.
//

import UIKit


enum RtAppTab: String, CaseIterable, Equatable {
    case bank
    case ca
    case dev
    case about

    var rawValue: String {
        switch self {
        case .bank:
            return "Банк"
        case .ca:
            return UIDevice.isPhone ? "УЦ" : "Удостоверяющий центр"
        case .dev:
            return "Разработка"
        case .about:
            return "О приложении"
        }
    }

    var imageName: String {
        var result: String

        switch self {
        case .ca:
            result = "tray.full.fill"
        case .bank:
            result = "person.crop.rectangle.stack.fill"
        case .about:
            result = "app.badge.fill"
        case .dev:
            result = "square.grid.2x2.fill"
        }

        return UIDevice.isPhone ? result : result.replacingOccurrences(of: ".fill", with: "")
    }
}
