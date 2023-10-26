//
//  RtAppTab.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 26.10.2023.
//

enum RtAppTab: String, CaseIterable, Equatable {
    case bank = "Банк"
    case ca = "УЦ"
    case dev = "Разработка"
    case about = "О приложении"

    var imageName: String {
        switch self {
        case .ca:
            return "tray.full.fill"
        case .bank:
            return "person.crop.rectangle.stack.fill"
        case .about:
            return "app.badge.fill"
        case .dev:
            return "square.grid.2x2.fill"
        }
    }
}
