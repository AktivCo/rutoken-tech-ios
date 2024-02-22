//
//  String+getDate.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 13.03.2024.
//

import Foundation


extension String {
    func getDate(with format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: self)
    }
}
