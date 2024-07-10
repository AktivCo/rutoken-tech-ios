//
//  Pkcs11KeyAlgorithm.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 05.03.2024.
//

enum Pkcs11KeyAlgorithm {
    case gostR3410_2012_256

    var rawValue: CK_ULONG {
        switch self {
        case .gostR3410_2012_256:
            return CKK_GOSTR3410
        }
    }
}
