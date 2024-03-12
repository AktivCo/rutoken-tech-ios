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
}


class Pkcs11Object: Pkcs11ObjectProtocol {
    private(set) var handle: CK_OBJECT_HANDLE
    private weak var session: Pkcs11Session?

    init(with handle: CK_OBJECT_HANDLE, _ session: Pkcs11Session) {
        self.handle = handle
        self.session = session
    }

    lazy var id: String? = {
        guard let dataId = try? getValue(for: AttributeType.id(nil, 0), with: handle, with: session) else {
            return nil
        }
        return String(decoding: dataId, as: UTF8.self)
    }()

    lazy var body: Data? = {
        guard let value = try? getValue(for: AttributeType.value(nil, 0), with: handle, with: session) else {
            return nil
        }
        return value
    }()

    private func getValue(for attr: AttributeType, with handle: CK_OBJECT_HANDLE, with session: Pkcs11Session?) throws -> Data {
        guard let session else {
            throw TokenError.generalError
        }

        var template = [attr].map { $0.attr }
        var rv = C_GetAttributeValue(session.handle, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw TokenError.generalError
        }

        template[0].pValue = UnsafeMutableRawPointer.allocate(byteCount: Int(template[0].ulValueLen), alignment: 1)
        defer {
            template[0].pValue.deallocate()
        }

        rv = C_GetAttributeValue(session.handle, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw TokenError.generalError
        }

        return Data(buffer: UnsafeBufferPointer(start: template[0].pValue.assumingMemoryBound(to: UInt8.self),
                                                count: Int(template[0].ulValueLen)))
    }
}

struct Pkcs11KeyPair {
    let pubKey: Pkcs11ObjectProtocol
    let privateKey: Pkcs11ObjectProtocol

    var algorithm: KeyAlgorithm {
        .gostR3410_2012_256
    }
}
