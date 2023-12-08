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
        var middlewares: [any Middleware<AppAction>] = []
        let pkcsHelper = Pkcs11Helper(with: RtEngineWrapper())
        let pcscHelper = PcscHelper(pcscWrapper: RtPcscWrapper())
        let cryptoManager = CryptoManager(pkcs11Helper: pkcsHelper, pcscHelper: pcscHelper)

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
