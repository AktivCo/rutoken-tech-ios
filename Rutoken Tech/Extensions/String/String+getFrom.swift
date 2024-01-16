//
//  String+getFrom.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 05.12.2023.
//

extension String {
    static func getFrom(_ subject: Any) -> String? {
        let mirror = Mirror(reflecting: subject)
        let arr = mirror.children.compactMap { $0.value as? UInt8 }

        guard arr.count == mirror.children.count else {
            return nil
        }

        guard let str = String(bytes: arr, encoding: .utf8) else {
            return nil
        }
        return str
    }
}
