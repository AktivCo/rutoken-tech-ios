//
//  KeychainManagerMock.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 01.03.2024.
//

import RutokenKeychainManager


class RutokenKeychainManagerMock: RutokenKeychainManagerProtocol {
    func set<T>(_ value: T, forKey key: String, with access: RTAccessibilityType) -> Bool where T: Codable {
        setCallback(value, key, access)
    }

    var setCallback: (_ value: Codable, _ key: String, _ access: RTAccessibilityType) -> Bool = { _, _, _ in true }

    func get<T>(_ key: String) -> T? where T: Codable {
        getCallback(key) as? T
    }

    var getCallback: (_ key: String) -> Codable? = { _ in nil }

    func clear() -> Bool {
        clearResult
    }

    var clearResult: Bool = false

    func delete(_ key: String) -> Bool {
        true
    }

    var deleteCallback: (String) -> Bool = { _ in true }
}
