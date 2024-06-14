//
//  KeychainHelper.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 14.06.2024.
//

import Foundation
import Security


public protocol KeychainHelperProtocol {
    func set<T: Codable>(_ value: T, forKey key: String, with access: RTAccessibilityType) -> Bool
    func get<T: Codable>(_ key: String) -> T?
    @discardableResult func clear() -> Bool
    @discardableResult func delete(_ key: String) -> Bool
}

public enum RTAccessibilityType {
    case any
    case biometryOrPasscode

    var getKSecAttrAccessible: SecAccessControl? {
        switch self {
        case .any:
            return SecAccessControlCreateWithFlags(nil,
                                                   kSecAttrAccessibleWhenUnlocked,
                                                   [],
                                                   nil)
        case .biometryOrPasscode:
            return SecAccessControlCreateWithFlags(nil,
                                                   kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                   .userPresence,
                                                   nil)
        }
    }
}

public class KeychainHelper: KeychainHelperProtocol {
    private let lock = NSLock()

    public init() {}

    @discardableResult
    private func remove(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    @discardableResult
    public func set<T: Codable>(_ value: T, forKey key: String, with accessType: RTAccessibilityType = .any) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard let data = try? JSONEncoder().encode(value) else {
            return false
        }

        remove(key)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: accessType.getKSecAttrAccessible as Any
        ]

        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    public func get<T: Codable>(_ key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?

        let errCode = withUnsafeMutablePointer(to: &result, {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        })

        guard errCode == errSecSuccess else {
            return nil
        }

        guard let data = result as? Data else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: data)
    }

    @discardableResult
    public func clear() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let query: [String: Any] = [ kSecClass as String: kSecClassGenericPassword]

        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    @discardableResult
    public func delete(_ key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        return remove(key)
    }
}

