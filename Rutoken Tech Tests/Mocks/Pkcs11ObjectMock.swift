//
//  Pkcs11ObjectMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 12.01.2024.
//

import Foundation

@testable import Rutoken_Tech


struct Pkcs11ObjectMock: Pkcs11ObjectProtocol {
    let handle = CK_OBJECT_HANDLE(NULL_PTR)

    var bufferValues: [Pkcs11BufferAttribute.AttrType: Result<Data, Error>] = [:]
    var uLongValues: [Pkcs11ULongAttribute.AttrType: Result<CK_ULONG, Error>] = [:]
    var boolValues: [Pkcs11BoolAttribute.AttrType: Result<Bool, Error>] = [:]

    func getValue(forAttr attrType: Pkcs11BufferAttribute.AttrType) throws -> Data {
        guard let value = bufferValues[attrType] else {
            return Data()
        }

        switch value {
        case let .success(data):
            return data
        case let .failure(error):
            throw error
        }
    }

    func getValue(forAttr attrType: Pkcs11ULongAttribute.AttrType) throws -> CK_ULONG {
        guard let value = uLongValues[attrType] else {
            return CK_ULONG()
        }

        switch value {
        case let .success(uLong):
            return uLong
        case let .failure(error):
            throw error
        }
    }

    func getValue(forAttr attrType: Pkcs11BoolAttribute.AttrType) throws -> Bool {
        guard let value = boolValues[attrType] else {
            return Bool()
        }

        switch value {
        case let .success(bool):
            return bool
        case let .failure(error):
            throw error
        }
    }

    mutating func setValue(forAttr attrType: Pkcs11BufferAttribute.AttrType, value: Result<Data, Error>) {
        bufferValues[attrType] = value
    }

    mutating func setValue(forAttr attrType: Pkcs11ULongAttribute.AttrType, value: Result<CK_ULONG, Error>) {
        uLongValues[attrType] = value
    }

    mutating func setValue(forAttr attrType: Pkcs11BoolAttribute.AttrType, value: Result<Bool, Error>) {
        boolValues[attrType] = value
    }
}
