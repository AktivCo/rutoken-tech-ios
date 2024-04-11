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
        var middlewares: [any Middleware<AppAction>] = []

        if !ProcessInfo.isPreview {
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

            middlewares = [
                OnStartMonitoring(cryptoManager: cryptoManager, userManager: userManager, documentManager: documentManager),
                // CA
                OnPerformTokenConnection(cryptoManager: cryptoManager),
                OnPerformGenKeyPair(cryptoManager: cryptoManager),
                OnPerformGenCert(cryptoManager: cryptoManager),
                // Bank
                OnPerformReadCerts(cryptoManager: cryptoManager, userManager: userManager),
                OnSelectCert(userManager: userManager),
                OnSavePin(pinCodeManager: pinCodeManager),
                OnGetPin(pinCodeManager: pinCodeManager),
                OnDeletePin(pinCodeManager: pinCodeManager),
                OnDeleteUser(userManager: userManager),
                OnAuthUser(cryptoManager: cryptoManager),
                OnResetDocuments(manager: documentManager),
                OnSignDocumentMiddleware(cryptoManager: cryptoManager, documentManager: documentManager),
                // About
                OnHandleOpenLink(),
                OnInitCooldownNfc()
            ]
        }

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
