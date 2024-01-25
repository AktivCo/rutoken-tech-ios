//
//  String+generateID.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 15.01.2024.
//

import Foundation


extension String {
    static func generateID() -> String {
        return String(format: "%08x-%08x", UInt32.random(in: 0...UInt32.max), UInt32.random(in: 0...UInt32.max))
    }
}
