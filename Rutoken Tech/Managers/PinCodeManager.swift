//
//  PinCodeManager.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 26.02.2024.
//


protocol PinCodeManagerProtocol {
    func savePin(pin: String, for serial: String, withBio: Bool)
    func deletePin(for serial: String)
    func getPin(for serial: String) -> String?
}

class PinCodeManager: PinCodeManagerProtocol {
    private let keychainManager: KeychainHelperProtocol

    init(keychainManager: KeychainHelperProtocol) {
        self.keychainManager = keychainManager
    }

    func savePin(pin: String, for serial: String, withBio: Bool) {
        _ = keychainManager.set(pin, forKey: serial, with: withBio ? .biometryOrPasscode : .any)
    }

    func deletePin(for serial: String) {
        _ = keychainManager.delete(serial)
    }

    func getPin(for serial: String) -> String? {
        keychainManager.get(serial)
    }
}
