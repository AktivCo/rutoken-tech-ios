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
    private let vcrManager: VcrManagerProtocol?

    private var cancellable = Set<AnyCancellable>()

    init(cryptoManager: CryptoManagerProtocol,
         userManager: UserManagerProtocol,
         documentManager: DocumentManagerProtocol,
         vcrManager: VcrManagerProtocol?) {
        self.cryptoManager = cryptoManager
        self.userManager = userManager
        self.documentManager = documentManager
        self.vcrManager = vcrManager
    }

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case .appLoaded = action else {
            return nil
        }

        return AsyncStream<AppAction> { continuation in
            do {
                try cryptoManager.startMonitoring()
            } catch {
                continuation.yield(.handleError(error))
            }

            userManager.users.sink { users in
                continuation.yield(.updateUsers(users))
            }
            .store(in: &cancellable)

            documentManager.documents.sink {
                continuation.yield(.updateDocuments($0))
            }
            .store(in: &cancellable)

            vcrManager?.vcrs.sink {
                continuation.yield(.updateVcrList($0))
            }
            .store(in: &cancellable)

            vcrManager?.didNewVcrConnected.sink { _ in
                continuation.yield(.hideVcrView)
                continuation.yield(.invalidateQrCodeTimer)
                Task {
                    // We want to nil QR-code after sheet completely disappears, 500ms seems enough for it
                    try? await Task.sleep(for: .milliseconds(500))
                    continuation.yield(.updateQrCode(nil))
                }
            }
            .store(in: &cancellable)

            cryptoManager.tokenState.sink {
                switch $0 {
                case .ready, .cooldown(0): continuation.yield(.updateActionWithTokenButtonState(.ready))
                case .inProgress: continuation.yield(.updateActionWithTokenButtonState(.inProgress))
                case .cooldown(let left): continuation.yield(.updateActionWithTokenButtonState(.cooldown(left)))
                }
            }
            .store(in: &cancellable)
        }
    }
}
