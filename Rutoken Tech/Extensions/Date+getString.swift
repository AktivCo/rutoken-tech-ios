//
//  Date+getString.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 27.02.2024.
//

import Foundation


extension Date {
    func getString(as format: String, locale: Locale = Locale(identifier: "ru_RU")) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
