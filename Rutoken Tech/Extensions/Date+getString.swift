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
}
