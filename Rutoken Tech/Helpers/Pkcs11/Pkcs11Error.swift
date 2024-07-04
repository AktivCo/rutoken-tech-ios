//
//  Pkcs11Error.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2024-06-14.
//


enum Pkcs11Error: Error, Equatable {
    case incorrectPin
    case internalError(rv: UInt? = nil)
}
