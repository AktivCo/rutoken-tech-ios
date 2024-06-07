//
//  Pkcs11Object.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 22.12.2023.
//

import Foundation


protocol Pkcs11ObjectProtocol {
    var handle: CK_OBJECT_HANDLE { get }

    func getValue(forAttr attrType: Pkcs11BufferAttribute.AttrType) throws -> Data
    func getValue(forAttr attrType: Pkcs11ULongAttribute.AttrType) throws -> CK_ULONG
    func getValue(forAttr attrType: Pkcs11BoolAttribute.AttrType) throws -> Bool
}

class Pkcs11Object: Pkcs11ObjectProtocol {
    static func getCertBaseTemplate() -> [any Pkcs11Attribute] {
        [
            Pkcs11ULongAttribute(type: .classObject, value: CKO_CERTIFICATE),
            Pkcs11BoolAttribute(type: .token, value: true),
            Pkcs11ULongAttribute(type: .certType, value: CKC_X_509)
        ]
    }

    static func getPubKeyBaseTemplate() -> [any Pkcs11Attribute] {
        [
            Pkcs11ULongAttribute(type: .classObject, value: CKO_PUBLIC_KEY),
            Pkcs11BoolAttribute(type: .token, value: true),
            Pkcs11BoolAttribute(type: .privateness, value: false)
        ]
    }

    static func getPrivKeyBaseTemplate() -> [any Pkcs11Attribute] {
        [
            Pkcs11ULongAttribute(type: .classObject, value: CKO_PRIVATE_KEY),
            Pkcs11BoolAttribute(type: .token, value: true),
            Pkcs11BoolAttribute(type: .privateness, value: true)
        ]
    }

    private(set) var handle: CK_OBJECT_HANDLE
    private weak var session: Pkcs11Session?

    init(with handle: CK_OBJECT_HANDLE, _ session: Pkcs11Session) {
        self.handle = handle
        self.session = session
    }

    func getValue(forAttr attrType: Pkcs11BufferAttribute.AttrType) throws -> Data {
        guard let session else {
            throw Pkcs11TokenError.generalError
        }

        // We have to calculate buffer size with C_GetAttributeValue call with nil-pointed Attribute
        // This step is neccessary only for buffer attributes and can be skipped for plain ones.
        var template = [Pkcs11BufferAttribute(type: attrType).attribute]
        var rv = C_GetAttributeValue(session.handle, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw Pkcs11TokenError.generalError
        }

        let attr = Pkcs11BufferAttribute(type: attrType, count: Int(template[0].ulValueLen))
        template = [attr.attribute]

        rv = C_GetAttributeValue(session.handle, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw Pkcs11TokenError.generalError
        }

        return Data(buffer: UnsafeBufferPointer(start: template[0].pValue.assumingMemoryBound(to: UInt8.self),
                                                count: Int(template[0].ulValueLen)))
    }

    func getValue(forAttr attrType: Pkcs11ULongAttribute.AttrType) throws -> CK_ULONG {
        guard let session else {
            throw Pkcs11TokenError.generalError
        }

        let attr = Pkcs11ULongAttribute(type: attrType, value: 0)
        var template = [attr.attribute]
        let rv = C_GetAttributeValue(session.handle, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw Pkcs11TokenError.generalError
        }

        return template[0].pValue.assumingMemoryBound(to: CK_ULONG.self).pointee
    }

    func getValue(forAttr attrType: Pkcs11BoolAttribute.AttrType) throws -> Bool {
        guard let session else {
            throw Pkcs11TokenError.generalError
        }

        let attr = Pkcs11BoolAttribute(type: attrType, value: false)
        var template = [attr.attribute]
        let rv = C_GetAttributeValue(session.handle, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw Pkcs11TokenError.generalError
        }

        return template[0].pValue.assumingMemoryBound(to: Bool.self).pointee
    }
}
