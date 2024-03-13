//
//  OnStartMonitoring.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 12.02.2024.
//

import Combine

import TinyAsyncRedux


class OnStartMonitoring: Middleware {
    private let cryptoManager: CryptoManagerProtocol
    private let userManager: UserManagerProtocol

    private var cancellable = Set<AnyCancellable>()

    init(cryptoManager: CryptoManagerProtocol, userManager: UserManagerProtocol) {
        self.cryptoManager = cryptoManager
        self.userManager = userManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case .appLoaded = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            do {
                try cryptoManager.startMonitoring()
            } catch {
                continuation.yield(.showAlert(.unknownError))
            }
            userManager.users.sink { users in
                continuation.yield(.updateUsers(users))
            }
            .store(in: &cancellable)
        }
    }
}
