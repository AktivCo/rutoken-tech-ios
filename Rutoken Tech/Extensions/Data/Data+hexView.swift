//
//  Data+hexView.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 13.09.2024.
//

import Foundation


extension Data {
    func hexView() -> String {
        return map { String(format: "%02x", $0) }.joined(separator: ":")
    }
}
