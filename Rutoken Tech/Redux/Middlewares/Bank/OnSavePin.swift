//
//  OnSave  Pin.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 26.02.2024.
//

import TinyAsyncRedux


class OnSavePin: Middleware {
    private let pinCodeManager: PinCodeManagerProtocol

    init(pinCodeManager: PinCodeManagerProtocol) {
        self.pinCodeManager = pinCodeManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .savePin(pin, serial, withBio) = action else {
            return nil
        }

        pinCodeManager.savePin(pin: pin, for: serial, withBio: withBio)
        return nil
    }
}
