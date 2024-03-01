//
//  OnSelectCert.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 01.03.2024.
//

import TinyAsyncRedux


class OnSelectCert: Middleware {
    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .selectCert(cert) = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            defer {
                continuation.finish()
            }

            continuation.yield(.addUser(.init(fullname: cert.name, title: cert.jobTitle, expiryDate: cert.expiryDate)))
            continuation.yield(.hideSheet)
        }
    }
}
