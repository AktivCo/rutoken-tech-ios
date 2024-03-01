//
//  OnDeletePin.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 01.03.2024.
//

import TinyAsyncRedux


class OnDeletePin: Middleware {
    private let pinCodeManager: PinCodeManagerProtocol

    init(pinCodeManager: PinCodeManagerProtocol) {
        self.pinCodeManager = pinCodeManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .deletePin(serial) = action else {
            return nil
        }

        pinCodeManager.deletePin(for: serial)
        return nil
    }
}
