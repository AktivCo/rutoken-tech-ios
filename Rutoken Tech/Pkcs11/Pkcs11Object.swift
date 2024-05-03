//
//  Pkcs11Object.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 22.12.2023.
//

import Foundation


protocol Pkcs11ObjectProtocol {
    var id: String? { get }
    var body: Data? { get }
    var handle: CK_OBJECT_HANDLE { get }
    func getValue(for attr: BufferAttribute) throws -> Data?
}

class Pkcs11Object: Pkcs11ObjectProtocol {
    private(set) var handle: CK_OBJECT_HANDLE
    private weak var session: Pkcs11Session?

    init(with handle: CK_OBJECT_HANDLE, _ session: Pkcs11Session) {
        self.handle = handle
        self.session = session
    }

    lazy var id: String? = {
        guard let dataId = try? getValue(for: BufferAttribute(type: .id)) else {
            return nil
        }
        return String(decoding: dataId, as: UTF8.self)
    }()

    lazy var body: Data? = {
        guard let value = try? getValue(for: BufferAttribute(type: .value)) else {
            return nil
        }
        return value
    }()

    func getValue(for attr: BufferAttribute) throws -> Data? {
        guard let session else {
            throw TokenError.generalError
        }

        var template = [attr.attribute]
        var rv = C_GetAttributeValue(session.handle, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw TokenError.generalError
        }

        let attr = BufferAttribute(type: attr.type, count: Int(template[0].ulValueLen))
        template = [attr.attribute]

        rv = C_GetAttributeValue(session.handle, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw TokenError.generalError
        }

        return attr.getValue
    }
}

struct Pkcs11KeyPair {
    let pubKey: Pkcs11ObjectProtocol
    let privateKey: Pkcs11ObjectProtocol

    var algorithm: KeyAlgorithm {
        .gostR3410_2012_256
    }
}
