//
//  OnGetTokenPin.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 29.02.2024.
//

import TinyAsyncRedux


class OnGetTokenPin: Middleware {
    private let pinCodeManager: PinCodeManagerProtocol

    init(pinCodeManager: PinCodeManagerProtocol) {
        self.pinCodeManager = pinCodeManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .getPin(serial) = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            defer {
                continuation.finish()
            }
            let pin = pinCodeManager.getPin(for: serial)
            continuation.yield(.updatePin(pin))
        }
    }
}
