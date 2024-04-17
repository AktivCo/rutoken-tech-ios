//
//  OnSelectCert.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 01.03.2024.
//

import TinyAsyncRedux


class OnSelectCert: Middleware {
    private let userManager: UserManagerProtocol

    init(userManager: UserManagerProtocol) {
        self.userManager = userManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .selectCert(cert) = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            defer {
                continuation.finish()
            }

            let user = try? userManager.createUser(from: cert)
            guard let user else {
                continuation.yield(.showAlert(.unknownError))
                return
            }
            continuation.yield(.selectUser(user.toBankUserInfo()))
            continuation.yield(.prepareDocuments)
            continuation.yield(.hideSheet)
        }
    }
}
