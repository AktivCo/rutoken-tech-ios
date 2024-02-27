//
//  PinCodeManager.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 26.02.2024.
//

protocol PinCodeManagerProtocol {
    func savePin(pin: String, for serial: String, withBio: Bool)
}

class PinCodeManager: PinCodeManagerProtocol {
    func savePin(pin: String, for serial: String, withBio: Bool) {}
}
