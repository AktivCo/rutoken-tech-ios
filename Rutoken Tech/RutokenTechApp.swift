//
//  Rutoken_TechApp.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2023-09-29.
//

import CoreData
import SwiftUI

import RtPcscWrapper
import RutokenKeychainManager
import TinyAsyncRedux


@main
struct RutokenTechApp: App {
    let store: Store<AppState, AppAction>

    init() {
        let userManager = UserManager()
        guard let fileHelper = FileHelper(dirName: "BankTempDir"),
              let documentManager = DocumentManager(helper: fileHelper) else {
            fatalError("Failed to initialize FileHelper")
        }
        let engineWrapper = RtEngineWrapper()
        let openSslHelper = OpenSslHelper(engine: engineWrapper)

        let pkcsHelper = Pkcs11Helper(with: engineWrapper)
        let pcscHelper = PcscHelper(pcscWrapper: RtPcscWrapper())
        let pinCodeManager = PinCodeManager(keychainManager: RutokenKeychainManager())

        let cryptoManager = CryptoManager(pkcs11Helper: pkcsHelper,
                                          pcscHelper: pcscHelper,
                                          openSslHelper: openSslHelper,
                                          fileHelper: fileHelper)

        let middlewares: [any Middleware<AppAction>] = [
            OnStartMonitoring(cryptoManager: cryptoManager, userManager: userManager, documentManager: documentManager),
            // CA
            OnPerformTokenConnection(cryptoManager: cryptoManager),
            OnPerformGenKeyPair(cryptoManager: cryptoManager),
            OnPerformGenCert(cryptoManager: cryptoManager),
            // Bank
            OnPerformReadCerts(cryptoManager: cryptoManager),
            OnSaveTokenPin(pinCodeManager: pinCodeManager),
            OnSelectCert(userManager: userManager),
            OnDeletePin(pinCodeManager: pinCodeManager),
            // About
            OnHandleOpenLink(),
            OnInitCooldownNfc()
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
