//
//  Pkcs11Object.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 22.12.2023.
//

import Foundation

import RtMock


@RtMock
protocol Pkcs11ObjectProtocol {
    var handle: CK_OBJECT_HANDLE { get }

    func getValue(forAttr attrType: Pkcs11DataAttribute) throws -> Data
    func getValue(forAttr attrType: Pkcs11CkUlongAttribute) throws -> UInt
    func getValue(forAttr attrType: Pkcs11BoolAttribute) throws -> Bool
}

class Pkcs11Object: Pkcs11ObjectProtocol {
    private(set) var handle: CK_OBJECT_HANDLE
    private weak var session: Pkcs11Session?

    init(with handle: CK_OBJECT_HANDLE, _ session: Pkcs11Session) {
        self.handle = handle
        self.session = session
    }

    func getValue(forAttr attrType: Pkcs11DataAttribute) throws -> Data {
        guard let session else {
            throw Pkcs11Error.internalError()
        }

        // We have to calculate buffer size with C_GetAttributeValue call with nil-pointed Attribute
        // This step is neccessary only for buffer attributes and can be skipped for plain ones.
        let size = try Pkcs11Template()
            .add(attr: attrType)
            .withCkTemplate {
                let rv = C_GetAttributeValue(session.handle, handle, &$0, CK_ULONG($0.count))
                guard rv == CKR_OK else {
                    throw Pkcs11Error.internalError(rv: rv)
                }

                return Int($0[0].ulValueLen)
        }

        return try Pkcs11Template()
            .add(attr: attrType, value: Data(repeating: 0, count: size))
            .withCkTemplate {
                let rv = C_GetAttributeValue(session.handle, handle, &$0, CK_ULONG($0.count))
                guard rv == CKR_OK else {
                    throw Pkcs11Error.internalError(rv: rv)
                }

                return Data(buffer: UnsafeBufferPointer(start: $0[0].pValue.assumingMemoryBound(to: UInt8.self),
                                                        count: Int($0[0].ulValueLen)))
        }
    }

    func getValue(forAttr attrType: Pkcs11CkUlongAttribute) throws -> CK_ULONG {
        guard let session else {
            throw Pkcs11Error.internalError()
        }

        let template = Pkcs11Template().add(attr: attrType, value: 0)
        return try template.withCkTemplate {
            let rv = C_GetAttributeValue(session.handle, handle, &$0, CK_ULONG($0.count))
            guard rv == CKR_OK else {
                throw Pkcs11Error.internalError(rv: rv)
            }

            return $0[0].pValue.assumingMemoryBound(to: CK_ULONG.self).pointee
        }
    }

    func getValue(forAttr attrType: Pkcs11BoolAttribute) throws -> Bool {
        guard let session else {
            throw Pkcs11Error.internalError()
        }

        let template = Pkcs11Template().add(attr: attrType, value: false)
        return try template.withCkTemplate {
            let rv = C_GetAttributeValue(session.handle, handle, &$0, CK_ULONG($0.count))
            guard rv == CKR_OK else {
                throw Pkcs11Error.internalError(rv: rv)
            }

            return $0[0].pValue.assumingMemoryBound(to: Bool.self).pointee
        }
    }
}
