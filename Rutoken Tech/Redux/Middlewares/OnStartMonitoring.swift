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
    private let documentManager: DocumentManagerProtocol

    private var cancellable = Set<AnyCancellable>()

    init(cryptoManager: CryptoManagerProtocol, userManager: UserManagerProtocol, documentManager: DocumentManagerProtocol) {
        self.cryptoManager = cryptoManager
        self.userManager = userManager
        self.documentManager = documentManager
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
            documentManager.documents.sink {
                continuation.yield(.updateDocs($0))
            }
            .store(in: &cancellable)
        }
    }
}
