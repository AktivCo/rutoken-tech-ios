//
//  String+hasCyrillic.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 18.01.2024.
//

extension String {
    var hasCyrillic: Bool {
        for unicode in self.unicodeScalars {
            if 1024 < unicode.value && unicode.value < 1279 {
                return true
            }
        }
        return false
    }
}
