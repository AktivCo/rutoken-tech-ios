//
//  Pkcs11Object.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 22.12.2023.
//

import Foundation


protocol Pkcs11Object {
    var id: String { get }
    var body: Data? { get }
}

extension Pkcs11Object {
    func getValue(for attr: AttributeType, with handle: CK_OBJECT_HANDLE, with session: CK_SESSION_HANDLE) throws -> Data {
        var template = [attr].map { $0.attr }
        var rv = C_GetAttributeValue(session, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw TokenError.generalError
        }

        template[0].pValue = UnsafeMutableRawPointer.allocate(byteCount: Int(template[0].ulValueLen), alignment: 1)
        defer {
            template[0].pValue.deallocate()
        }

        rv = C_GetAttributeValue(session, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw TokenError.generalError
        }

        return Data(buffer: UnsafeBufferPointer(start: template[0].pValue.assumingMemoryBound(to: UInt8.self),
                                                count: Int(template[0].ulValueLen)))
    }
}

struct Pkcs11Cert: Pkcs11Object {
    private(set) var id: String = ""
    private(set) var body: Data?

    init?(with handle: CK_OBJECT_HANDLE, _ session: CK_SESSION_HANDLE) {
        guard let dataId = try? getValue(for: AttributeType.id(nil, 0), with: handle, with: session) else {
            return nil
        }
        self.id = String(decoding: dataId, as: UTF8.self)

        guard let value = try? getValue(for: AttributeType.value(nil, 0), with: handle, with: session) else {
            return nil
        }
        self.body = value
    }
}

struct Pkcs11PrivateKey: Pkcs11Object {
    private(set) var id: String = ""
    private(set) var body: Data?

    init?(with handle: CK_OBJECT_HANDLE, _ session: CK_SESSION_HANDLE) {
        guard let dataId = try? getValue(for: AttributeType.id(nil, 0), with: handle, with: session) else {
            return nil
        }
        self.id = String(decoding: dataId, as: UTF8.self)
    }
}

struct Pkcs11PublicKey: Pkcs11Object {
    private(set) var id: String = ""
    private(set) var body: Data?

    init?(with handle: CK_OBJECT_HANDLE, _ session: CK_SESSION_HANDLE) {
        guard let dataId = try? getValue(for: AttributeType.id(nil, 0), with: handle, with: session) else {
            return nil
        }
        self.id = String(decoding: dataId, as: UTF8.self)

        guard let value = try? getValue(for: AttributeType.value(nil, 0), with: handle, with: session) else {
            return nil
        }
        self.body = value
    }
}

struct Pkcs11KeyPair {
    let pubKey: Pkcs11Object
    let privateKey: Pkcs11Object
}
