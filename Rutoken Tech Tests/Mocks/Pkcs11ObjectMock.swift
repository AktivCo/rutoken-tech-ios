//
//  Pkcs11ObjectMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 12.01.2024.
//

import Foundation

@testable import Rutoken_Tech


struct Pkcs11ObjectMock: Pkcs11Object {
    let id: String
    let body: Data?
}
