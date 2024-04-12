//
//  Date+getString.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 27.02.2024.
//

import Foundation


extension Date {
    func getString(with format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }

    var getRussianString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "dd MMMM yyyy"
        return dateFormatter.string(from: self)
    }

    var getRussianStringWithTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "dd MMMM yyyy 'г. в' HH:mm"
        return dateFormatter.string(from: self)
    }
}
