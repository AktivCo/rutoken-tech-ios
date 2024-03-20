//
//  String+withoutPathExtension.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 25.03.2024.
//

extension String {
    var withoutPathExtension: String {
        var components = self.components(separatedBy: ".")
        guard components.count > 1 else { return self }
        components.removeLast()
        return components.joined(separator: ".")
    }
}
