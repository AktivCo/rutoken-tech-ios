//
//  RutokenTechApp+defaultPin.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 11.04.2024.
//

extension RutokenTechApp {
    static var defaultPin: String {
#if DEBUG
        return "12345678"
#else
        return ""
#endif
    }
}
