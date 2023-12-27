//
//  Rutoken_TechApp.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2023-09-29.
//

import SwiftUI

import RtPcscWrapper
import TinyAsyncRedux


@main
struct RutokenTechApp: App {
    let store: Store<AppState, AppAction>

    init() {
        let pkcsHelper = Pkcs11Helper(with: RtEngineWrapper())
        let pcscHelper = PcscHelper(pcscWrapper: RtPcscWrapper())
        let cryptoManager = CryptoManager(pkcs11Helper: pkcsHelper, pcscHelper: pcscHelper)

        let middlewares: [any Middleware<AppAction>] = [
            OnPerformTokenConnection(cryptoManager: cryptoManager),
            OnPerformGenKeyPair(cryptoManager: cryptoManager)
        ]

        store = Store(initialState: AppState(),
                      reducer: AppReducer(),
                      middlewares: middlewares)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
