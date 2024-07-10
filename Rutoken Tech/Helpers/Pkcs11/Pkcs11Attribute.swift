//
//  Pkcs11Attribute.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 21.12.2023.
//

import Foundation


enum Pkcs11BoolAttribute {
    case token
    case derive
    case privateness

    var type: CK_ULONG {
        switch self {
        case .token: return CKA_TOKEN
        case .derive: return CKA_DERIVE
        case .privateness: return CKA_PRIVATE
        }
    }
}

enum Pkcs11CkUlongAttribute {
    case classObject
    case keyType
    case certType
    case certCategory
    case hwFeatureType

    var type: CK_ULONG {
        switch self {
        case .classObject: return CKA_CLASS
        case .keyType: return CKA_KEY_TYPE
        case .certType: return CKA_CERTIFICATE_TYPE
        case .certCategory: return CKA_CERTIFICATE_CATEGORY
        case .hwFeatureType: return CKA_HW_FEATURE_TYPE
        }
    }

}

enum Pkcs11DataAttribute {
    case id
    case value
    case gostR3410Params
    case gostR3411Params
    case startDate
    case endDate
    case vendorCurrentInterface
    case vendorSupportedInterface
    case vendorModelName

    var type: CK_ULONG {
        switch self {
        case .id: return CKA_ID
        case .value: return CKA_VALUE
        case .gostR3410Params: return CKA_GOSTR3410_PARAMS
        case .gostR3411Params: return CKA_GOSTR3411_PARAMS
        case .startDate: return CKA_START_DATE
        case .endDate: return CKA_END_DATE
        case .vendorCurrentInterface: return CKA_VENDOR_CURRENT_TOKEN_INTERFACE
        case .vendorSupportedInterface: return CKA_VENDOR_SUPPORTED_TOKEN_INTERFACE
        case .vendorModelName: return CKA_VENDOR_MODEL_NAME
        }
    }
}
