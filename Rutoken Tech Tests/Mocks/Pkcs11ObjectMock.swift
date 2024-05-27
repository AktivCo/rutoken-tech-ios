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

    var bufferValues: [BufferAttribute.AttrType: Result<Data, Error>] = [:]
    var uLongValues: [ULongAttribute.AttrType: Result<CK_ULONG, Error>] = [:]
    var boolValues: [BoolAttribute.AttrType: Result<Bool, Error>] = [:]

    func getValue(forAttr attrType: BufferAttribute.AttrType) throws -> Data {
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

    func getValue(forAttr attrType: ULongAttribute.AttrType) throws -> CK_ULONG {
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

    func getValue(forAttr attrType: BoolAttribute.AttrType) throws -> Bool {
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

    mutating func setValue(forAttr attrType: BufferAttribute.AttrType, value: Result<Data, Error>) {
        bufferValues[attrType] = value
    }

    mutating func setValue(forAttr attrType: ULongAttribute.AttrType, value: Result<CK_ULONG, Error>) {
        uLongValues[attrType] = value
    }

    mutating func setValue(forAttr attrType: BoolAttribute.AttrType, value: Result<Bool, Error>) {
        boolValues[attrType] = value
    }
}
