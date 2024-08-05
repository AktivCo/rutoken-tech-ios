//
//  KeyAlgorithm+description.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 05.03.2024.
//

extension Pkcs11KeyAlgorithm {
    var description: String {
        switch self {
        case .gostR3410_2012_256:
            return "ГОСТ Р 34.10-2012 256 бит"
        }
    }
}
