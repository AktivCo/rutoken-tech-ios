//
//  Data+random.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 13.09.2024.
//

import Foundation


extension Data {
    static func random(_ length: Int = 5) -> Data {
        return Data((0..<length).map { _ in UInt8.random(in: UInt8.min...UInt8.max) })
    }
}
