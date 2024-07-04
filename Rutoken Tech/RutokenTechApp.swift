//
//  Rutoken_TechApp.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2023-09-29.
//

import CoreData
import SwiftUI

import RtPcscWrapper
import TinyAsyncRedux


@main
struct RutokenTechApp: App {
    let store: Store<AppState, AppAction>

    init() {
        UIView.appearance().isMultipleTouchEnabled = false
        UIView.appearance().isExclusiveTouch = true

        var middlewares: [any Middleware<AppAction>] = []

        if !ProcessInfo.isPreview {
            let userManager = UserManager()
            let fileHelper = FileHelper()
            let fileSource = FileSourceHelper()
            guard let documentManager = DocumentManager(helper: fileHelper, fileSource: fileSource) else {
                fatalError("Failed to initialize DocumentManager")
            }
            let engineWrapper = RtEngineWrapper()
            let openSslHelper = OpenSslHelper()

            let pkcsHelper = Pkcs11Helper(with: engineWrapper)
            let pcscHelper = PcscHelper(pcscWrapper: RtPcscWrapper())
            let pinCodeManager = PinCodeManager(keychainManager: KeychainHelper())

            let cryptoManager = CryptoManager(pkcs11Helper: pkcsHelper,
                                              pcscHelper: pcscHelper,
                                              openSslHelper: openSslHelper,
                                              fileHelper: fileHelper,
                                              fileSource: fileSource)

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
                OnPrepareDocuments(cryptoManager: cryptoManager, documentManager: documentManager),
                OnResetDocuments(manager: documentManager),
                OnSignDocument(cryptoManager: cryptoManager, documentManager: documentManager),
                OnCmsVerify(cryptoManager: cryptoManager, documentManager: documentManager),
                OnEncryptDocument(cryptoManager: cryptoManager, documentManager: documentManager),
                OnDecryptCms(cryptoManager: cryptoManager, documentManager: documentManager),
                OnSelectDocument(documentManager: documentManager),
                // About
                OnHandleOpenLink()
            ]

            if !UIDevice.isPhone {
                let vcrManager = VcrManager()
                middlewares.append(OnGenerateQrCode(vcrManager: vcrManager))
            }
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
