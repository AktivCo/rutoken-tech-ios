//
//  AttributeType.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 21.12.2023.
//


private var certObject: CK_OBJECT_CLASS = CKO_CERTIFICATE
private var publicKeyObject: CK_OBJECT_CLASS = CKO_PUBLIC_KEY
private var privateKeyObject: CK_OBJECT_CLASS = CKO_PRIVATE_KEY
private var hwFeatureObject: CK_OBJECT_CLASS = CKO_HW_FEATURE

var hardwareFeatureType: CK_HW_FEATURE_TYPE = CKH_VENDOR_TOKEN_INFO

var keyTypeGostR3410_2012_256: CK_KEY_TYPE = CKK_GOSTR3410
var certTypeX509: CK_CERTIFICATE_TYPE = CKC_X_509
var certCategoryUser: CK_ULONG = 1

private var attributeTrue = CK_BBOOL(CK_TRUE)
private var attributeFalse = CK_BBOOL(CK_FALSE)

var parametersGostR3410_2012_256: [CK_BYTE] = [ 0x06, 0x07, 0x2a, 0x85, 0x03, 0x02, 0x02, 0x23, 0x02 ]
var parametersGostR3411_2012_256: [CK_BYTE] = [ 0x06, 0x08, 0x2a, 0x85, 0x03, 0x07, 0x01, 0x01, 0x02, 0x02 ]


enum AttributeType {
    enum ObjectClass {
        case cert
        case publicKey
        case privateKey
        case hwFeature
    }

    case objectClass(ObjectClass)
    case id(UnsafeMutableRawPointer?, UInt)
    case value(UnsafeMutableRawPointer?, UInt)
    case keyType(UnsafeMutableRawPointer?, UInt)
    case certX509(UnsafeMutableRawPointer?, UInt)
    case certCategory(UnsafeMutableRawPointer?, UInt)
    case attrTrue(UInt)
    case attrFalse(UInt)
    case gostR3410_2012_256_params
    case gostR3411_2012_256_params
    case hwFeatureType

    var attr: CK_ATTRIBUTE {
        switch self {
        case .objectClass(let object):
            switch object {
            case .cert:
                return CK_ATTRIBUTE(type: CKA_CLASS,
                                    pValue: &certObject,
                                    ulValueLen: CK_ULONG(MemoryLayout.size(ofValue: certObject)))
            case .publicKey:
                return CK_ATTRIBUTE(type: CKA_CLASS,
                                    pValue: &publicKeyObject,
                                    ulValueLen: CK_ULONG(MemoryLayout.size(ofValue: publicKeyObject)))
            case .privateKey:
                return CK_ATTRIBUTE(type: CKA_CLASS,
                                    pValue: &privateKeyObject,
                                    ulValueLen: CK_ULONG(MemoryLayout.size(ofValue: privateKeyObject)))
            case .hwFeature:
                return CK_ATTRIBUTE(type: CKA_CLASS,
                                    pValue: &hwFeatureObject,
                                    ulValueLen: CK_ULONG(MemoryLayout.size(ofValue: hwFeatureObject)))
            }
        case .id(let pointer, let len):
            return CK_ATTRIBUTE(type: CKA_ID,
                                pValue: pointer,
                                ulValueLen: CK_ULONG(len))
        case .value(let pointer, let len):
            return CK_ATTRIBUTE(type: CKA_VALUE,
                                pValue: pointer,
                                ulValueLen: CK_ULONG(len))
        case .keyType(let pointer, let len):
            return CK_ATTRIBUTE(type: CKA_KEY_TYPE,
                                pValue: pointer,
                                ulValueLen: CK_ULONG(len))
        case .certX509(let pointer, let len):
            return CK_ATTRIBUTE(type: CKA_CERTIFICATE_TYPE,
                                pValue: pointer,
                                ulValueLen: CK_ULONG(len))
        case .certCategory(let pointer, let len):
            return CK_ATTRIBUTE(type: CKA_CERTIFICATE_CATEGORY,
                                pValue: pointer,
                                ulValueLen: CK_ULONG(len))
        case let .attrTrue(type):
            return CK_ATTRIBUTE(type: type,
                                pValue: &attributeTrue,
                                ulValueLen: CK_ULONG(MemoryLayout.size(ofValue: attributeFalse)))
        case let .attrFalse(type):
            return CK_ATTRIBUTE(type: type,
                                pValue: &attributeFalse,
                                ulValueLen: CK_ULONG(MemoryLayout.size(ofValue: attributeFalse)))
        case .gostR3410_2012_256_params:
            return parametersGostR3410_2012_256.withUnsafeMutableBufferPointer { buf in
                return CK_ATTRIBUTE(type: CKA_GOSTR3410_PARAMS,
                                    pValue: buf.baseAddress!,
                                    ulValueLen: CK_ULONG(buf.count))
            }
        case .gostR3411_2012_256_params:
            return parametersGostR3411_2012_256.withUnsafeMutableBufferPointer { buf in
                return CK_ATTRIBUTE(type: CKA_GOSTR3411_PARAMS,
                                    pValue: buf.baseAddress!,
                                    ulValueLen: CK_ULONG(buf.count))
            }
        case .hwFeatureType:
            return CK_ATTRIBUTE(type: CKA_HW_FEATURE_TYPE,
                                pValue: &hardwareFeatureType,
                                ulValueLen: CK_ULONG(MemoryLayout.size(ofValue: hardwareFeatureType)))
        }
    }
}
