//
//  PkcsAttribute.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 21.12.2023.
//

import Foundation


enum PkcsConstants {
    static let gostR3410_2012_256_paramset_B: [CK_BYTE] = [ 0x06, 0x09, 0x2A, 0x85, 0x03, 0x07, 0x01, 0x02, 0x01, 0x01, 0x02 ]
    static let gostR3411_2012_256_params_oid: [CK_BYTE] = [ 0x06, 0x08, 0x2a, 0x85, 0x03, 0x07, 0x01, 0x01, 0x02, 0x02 ]
    static let CK_CERTIFICATE_CATEGORY_TOKEN_USER: CK_ULONG = 1
}

protocol PkcsAttribute {
    var attribute: CK_ATTRIBUTE { get }
}

class BoolAttribute: PkcsAttribute {
    enum AttrType {
        case token
        case derive
        case privateness

        var rawValue: CK_ULONG {
            switch self {
            case .token: return CKA_TOKEN
            case .derive: return CKA_DERIVE
            case .privateness: return CKA_PRIVATE
            }
        }
    }

    private let type: AttrType
    private let wrappedPointer: WrappedPointer<UnsafeMutablePointer<CK_BBOOL>>
    private let size: Int

    init(type: AttrType, value: Bool) {
        self.type = type
        self.wrappedPointer = WrappedPointer<UnsafeMutablePointer<CK_BBOOL>>({
            let ptr = UnsafeMutablePointer<CK_BBOOL>.allocate(capacity: 1)
            var temp = value ? CK_BBOOL(CK_TRUE) : CK_BBOOL(CK_FALSE)
            ptr.initialize(from: &temp, count: 1)
            return ptr
        }, {
            $0.deinitialize(count: 1)
            $0.deallocate()
        })
        self.size = MemoryLayout<CK_BBOOL>.size
    }

    var attribute: CK_ATTRIBUTE {
        CK_ATTRIBUTE(type: self.type.rawValue,
                     pValue: wrappedPointer.pointer,
                     ulValueLen: CK_ULONG(size))
    }
}

class ULongAttribute: PkcsAttribute {
    enum AttrType {
        case classObject
        case keyType
        case certType
        case certCategory
        case hwFeatureType

        var rawValue: CK_ULONG {
            switch self {
            case .classObject: return CKA_CLASS
            case .keyType: return CKA_KEY_TYPE
            case .certType: return CKA_CERTIFICATE_TYPE
            case .certCategory: return CKA_CERTIFICATE_CATEGORY
            case .hwFeatureType: return CKA_HW_FEATURE_TYPE
            }
        }
    }

    private let type: AttrType
    private let wrappedPointer: WrappedPointer<UnsafeMutablePointer<CK_ULONG>>
    private let size: Int

    init(type: AttrType, value: CK_ULONG) {
        self.type = type
        self.wrappedPointer = WrappedPointer<UnsafeMutablePointer<CK_ULONG>>({
            var temp = value
            let ptr = UnsafeMutablePointer<CK_ULONG>.allocate(capacity: 1)
            ptr.initialize(from: &temp, count: 1)
            return ptr
        }, {
            $0.deinitialize(count: 1)
            $0.deallocate()
        })
        self.size = MemoryLayout.size(ofValue: value)
    }

    var attribute: CK_ATTRIBUTE {
        CK_ATTRIBUTE(type: self.type.rawValue,
                     pValue: wrappedPointer.pointer,
                     ulValueLen: CK_ULONG(size))
    }
}

class BufferAttribute: PkcsAttribute {
    enum AttrType {
        case id
        case value
        case gostR3410Params
        case gostR3411Params
        case startDate
        case endDate
        case vendorCurrentInterface
        case vendorSupportedInterface
        case vendorModelName

        var rawValue: CK_ULONG {
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

    let type: AttrType
    private let wrappedPointer: WrappedPointer<UnsafeMutablePointer<UInt8>>?
    private let size: Int

    init(type: AttrType, value: Data) {
        self.type = type
        self.size = value.count
        self.wrappedPointer = WrappedPointer<UnsafeMutablePointer<UInt8>>({
            value.withUnsafeBytes { bytes in
                let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: bytes.count)
                ptr.initialize(from: bytes.baseAddress!.assumingMemoryBound(to: UInt8.self), count: bytes.count)
                return ptr
            }
        }, { [count = value.count] in
            $0.deinitialize(count: count)
            $0.deallocate()
        })
    }

    init(type: AttrType) {
        self.type = type
        self.size = 0
        self.wrappedPointer = nil
    }

    convenience init(type: AttrType, count: Int) {
        self.init(type: type, value: Data(repeating: 0, count: count))
    }

    var attribute: CK_ATTRIBUTE {
        CK_ATTRIBUTE(type: type.rawValue,
                     pValue: wrappedPointer?.pointer,
                     ulValueLen: CK_ULONG(size))
    }
}
