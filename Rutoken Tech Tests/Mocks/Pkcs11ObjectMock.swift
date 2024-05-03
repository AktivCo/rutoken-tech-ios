//
//  Pkcs11ObjectMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 12.01.2024.
//

import Foundation

@testable import Rutoken_Tech


struct Pkcs11ObjectMock: Pkcs11ObjectProtocol {
    let id: String?
    let body: Data?
    let handle = CK_OBJECT_HANDLE(NULL_PTR)

    func getValue(for attr: Rutoken_Tech.BufferAttribute) throws -> Data? { try getValueCallback() }
    var getValueCallback: () throws -> Data? = { Data() }
}
