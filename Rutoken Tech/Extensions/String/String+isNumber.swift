//
//  String+isNumber.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 18.01.2024.
//

import Foundation


extension String {
    var isNumber: Bool {
        let digitsCharacters = CharacterSet(charactersIn: "0123456789")
        return CharacterSet(charactersIn: self).isSubset(of: digitsCharacters)
    }
}
