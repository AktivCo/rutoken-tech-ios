//
//  Pkcs11Object.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 22.12.2023.
//

import Foundation


protocol Pkcs11ObjectProtocol {
    var handle: CK_OBJECT_HANDLE { get }

    func getValue(forAttr attrType: BufferAttribute.AttrType) throws -> Data
    func getValue(forAttr attrType: ULongAttribute.AttrType) throws -> CK_ULONG
    func getValue(forAttr attrType: BoolAttribute.AttrType) throws -> Bool
}

class Pkcs11Object: Pkcs11ObjectProtocol {
    static func getCertBaseTemplate() -> [any PkcsAttribute] {
        [
            ULongAttribute(type: .classObject, value: CKO_CERTIFICATE),
            BoolAttribute(type: .token, value: true),
            ULongAttribute(type: .certType, value: CKC_X_509)
        ]
    }

    static func getPubKeyBaseTemplate() -> [any PkcsAttribute] {
        [
            ULongAttribute(type: .classObject, value: CKO_PUBLIC_KEY),
            BoolAttribute(type: .token, value: true),
            BoolAttribute(type: .privateness, value: false)
        ]
    }

    static func getPrivKeyBaseTemplate() -> [any PkcsAttribute] {
        [
            ULongAttribute(type: .classObject, value: CKO_PRIVATE_KEY),
            BoolAttribute(type: .token, value: true),
            BoolAttribute(type: .privateness, value: true)
        ]
    }

    private(set) var handle: CK_OBJECT_HANDLE
    private weak var session: Pkcs11Session?

    init(with handle: CK_OBJECT_HANDLE, _ session: Pkcs11Session) {
        self.handle = handle
        self.session = session
    }

    func getValue(forAttr attrType: BufferAttribute.AttrType) throws -> Data {
        guard let session else {
            throw TokenError.generalError
        }

        // We have to calculate buffer size with C_GetAttributeValue call with nil-pointed Attribute
        // This step is neccessary only for buffer attributes and can be skipped for plain ones.
        var template = [BufferAttribute(type: attrType).attribute]
        var rv = C_GetAttributeValue(session.handle, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw TokenError.generalError
        }

        let attr = BufferAttribute(type: attrType, count: Int(template[0].ulValueLen))
        template = [attr.attribute]

        rv = C_GetAttributeValue(session.handle, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw TokenError.generalError
        }

        return Data(buffer: UnsafeBufferPointer(start: template[0].pValue.assumingMemoryBound(to: UInt8.self),
                                                count: Int(template[0].ulValueLen)))
    }

    func getValue(forAttr attrType: ULongAttribute.AttrType) throws -> CK_ULONG {
        guard let session else {
            throw TokenError.generalError
        }

        let attr = ULongAttribute(type: attrType, value: 0)
        var template = [attr.attribute]
        let rv = C_GetAttributeValue(session.handle, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw TokenError.generalError
        }

        return template[0].pValue.assumingMemoryBound(to: CK_ULONG.self).pointee
    }

    func getValue(forAttr attrType: BoolAttribute.AttrType) throws -> Bool {
        guard let session else {
            throw TokenError.generalError
        }

        let attr = BoolAttribute(type: attrType, value: false)
        var template = [attr.attribute]
        let rv = C_GetAttributeValue(session.handle, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw TokenError.generalError
        }

        return template[0].pValue.assumingMemoryBound(to: Bool.self).pointee
    }
}
