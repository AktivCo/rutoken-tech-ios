//
//  OnDeleteUser.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.03.2024.
//

import TinyAsyncRedux


class OnDeleteUser: Middleware {
    private let userManager: UserManagerProtocol

    init(userManager: UserManagerProtocol) {
        self.userManager = userManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .deleteUser(user) = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            defer {
                continuation.finish()
            }
            do {
                try userManager.deleteUser(user: user)
            } catch {
                continuation.yield(.showAlert(.unknownError))
            }
        }
    }
}
