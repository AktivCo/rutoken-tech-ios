//
//  Data+getDate.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 25.04.2024.
//

import Foundation


extension Data {
    func getDate(with format: String) -> Date? {
        String(decoding: self, as: UTF8.self).getDate(with: format)
    }
}
