//
//  PkcsAttribute.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 21.12.2023.
//

import Foundation


enum PkcsConstants {
    static let parametersGostR3410_2012_256: [CK_BYTE] = [ 0x06, 0x07, 0x2a, 0x85, 0x03, 0x02, 0x02, 0x23, 0x02 ]
    static let parametersGostR3411_2012_256: [CK_BYTE] = [ 0x06, 0x08, 0x2a, 0x85, 0x03, 0x07, 0x01, 0x01, 0x02, 0x02 ]
    static let CK_CERTIFICATE_CATEGORY_TOKEN_USER: CK_ULONG = 1

    static func createDateObject(with date: Date = Date()) -> CK_DATE? {
        var result = CK_DATE()

        guard let day = date.getString(with: "dd").createPointer(),
              let month = date.getString(with: "MM").createPointer(),
              let year = date.getString(with: "YYYY").createPointer() else {
            return nil
        }
        memcpy(&(result.day), day.pointer, 2)
        memcpy(&(result.month), month.pointer, 2)
        memcpy(&(result.year), year.pointer, 4)
        return result
    }
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
    private let wrappedPointer: WrappedPointer<UnsafeMutablePointer<CK_BBOOL>>?
    private let size: Int

    init(type: AttrType, value: Bool) {
        self.type = type
        self.wrappedPointer = WrappedPointer({
            let ptr = UnsafeMutablePointer<CK_BBOOL>.allocate(capacity: 1)
            var temp = value ? CK_BBOOL(CK_TRUE) : CK_BBOOL(CK_FALSE)
            ptr.initialize(from: &temp, count: 1)
            return ptr
        }, { $0.deallocate() })
        self.size = MemoryLayout<CK_BBOOL>.size
    }

    var attribute: CK_ATTRIBUTE {
        CK_ATTRIBUTE(type: self.type.rawValue,
                     pValue: wrappedPointer?.pointer,
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
    private let wrappedPointer: WrappedPointer<UnsafeMutablePointer<CK_ULONG>>?
    private let size: Int

    init(type: AttrType, value: CK_ULONG) {
        self.type = type
        wrappedPointer = WrappedPointer({
            var temp = value
            let ptr = UnsafeMutablePointer<CK_ULONG>.allocate(capacity: MemoryLayout.size(ofValue: value))
            ptr.initialize(from: &temp, count: MemoryLayout.size(ofValue: value))
            return ptr
        }, { $0.deallocate() })
        self.size = MemoryLayout.size(ofValue: value)
    }

    var attribute: CK_ATTRIBUTE {
        CK_ATTRIBUTE(type: self.type.rawValue,
                     pValue: wrappedPointer?.pointer,
                     ulValueLen: CK_ULONG(size))
    }
}

class BufferAttribute: PkcsAttribute {
    enum AttrType {
        case id
        case value
        case gostR3410Params
        case gostR3411Params
        case vendorCurrentInterface
        case vendorSupportedInterface

        var rawValue: CK_ULONG {
            switch self {
            case .id: return CKA_ID
            case .value: return CKA_VALUE
            case .gostR3410Params: return CKA_GOSTR3410_PARAMS
            case .gostR3411Params: return CKA_GOSTR3411_PARAMS
            case .vendorCurrentInterface: return CKA_VENDOR_CURRENT_TOKEN_INTERFACE
            case .vendorSupportedInterface: return CKA_VENDOR_SUPPORTED_TOKEN_INTERFACE
            }
        }
    }

    private let type: AttrType
    private let wrappedPointer: WrappedPointer<UnsafeMutablePointer<UInt8>>?
    private let size: Int

    init(type: AttrType, value: [UInt8]? = nil) {
        self.type = type
        wrappedPointer = WrappedPointer({
            if let value {
                var temp = value
                let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: value.count)
                ptr.initialize(from: &temp, count: value.count)
                return ptr
            }
            return nil
        }, { $0.deallocate() })
        self.size = value?.count ?? 0
    }

    var attribute: CK_ATTRIBUTE {
        CK_ATTRIBUTE(type: type.rawValue,
                     pValue: wrappedPointer?.pointer,
                     ulValueLen: CK_ULONG(size))
    }
}

class ObjectAttribute: PkcsAttribute {
    enum AttrType {
        case startDate(Date)
        case endDate(Date)

        var rawValue: CK_ULONG {
            switch self {
            case .startDate: return CKA_START_DATE
            case .endDate: return CKA_END_DATE
            }
        }

        var length: Int {
            switch self {
            case .startDate, .endDate:
                return MemoryLayout<CK_DATE>.size
            }
        }
    }

    private let type: AttrType
    private let wrappedPointer: WrappedPointer<UnsafeMutableRawPointer>?
    private let size: Int

    init(type: AttrType) {
        self.type = type
        self.wrappedPointer = WrappedPointer<UnsafeMutableRawPointer>({
            switch type {
            case .startDate(let date), .endDate(let date):
                if var dateObject = PkcsConstants.createDateObject(with: date) {
                    let ptr = UnsafeMutableRawPointer.allocate(byteCount: type.length, alignment: 1)
                    ptr.copyMemory(from: &dateObject, byteCount: MemoryLayout<CK_DATE>.size)
                    return ptr
                } else { return nil }
            }
        }, { $0.deallocate })
        self.size = type.length
    }

    var attribute: CK_ATTRIBUTE {
        CK_ATTRIBUTE(type: type.rawValue,
                     pValue: wrappedPointer?.pointer,
                     ulValueLen: CK_ULONG(size))
    }
}
