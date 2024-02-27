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
        let fileHelper = FileHelper()
        let engineWrapper = RtEngineWrapper()
        let openSslHelper = OpenSslHelper(engine: engineWrapper)

        let pkcsHelper = Pkcs11Helper(with: engineWrapper)
        let pcscHelper = PcscHelper(pcscWrapper: RtPcscWrapper())
        let pinCodeManager = PinCodeManager()

        let cryptoManager = CryptoManager(pkcs11Helper: pkcsHelper,
                                          pcscHelper: pcscHelper,
                                          openSslHelper: openSslHelper,
                                          fileHelper: fileHelper)

        let middlewares: [any Middleware<AppAction>] = [
            OnStartMonitoring(cryptoManager: cryptoManager),
            // CA
            OnPerformTokenConnection(cryptoManager: cryptoManager),
            OnPerformGenKeyPair(cryptoManager: cryptoManager),
            OnPerformGenCert(cryptoManager: cryptoManager),
            // Bank
            OnPerformReadCerts(cryptoManager: cryptoManager),
            OnSaveTokenPin(pinCodeManager: pinCodeManager),
            // About
            OnHandleOpenLink()
        ]

        store = Store(initialState: AppState(),
                      reducer: AppReducer(),
                      middlewares: middlewares)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .onAppear {
                    store.send(.appLoaded)
                }
        }
    }
}
