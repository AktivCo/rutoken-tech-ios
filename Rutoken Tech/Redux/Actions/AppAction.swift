//
//  AppAction.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 22.11.2023.
//

import SwiftUI

import RtUiComponents


enum AppAction {
    // MARK: Errors, Alerts & Sheets
    case showAlert(AppAlert)
    case hideAlert
    case showSheet(Bool, RtSheetSize, any View)
    case hideSheet
    case showPinInputError(String)
    case hidePinInputError

    // MARK: Initialization
    case appLoaded

    // MARK: Token Selection
    case selectToken(RtTokenType, String)
    case tokenSelected(TokenInfo, String)
    case logoutCa

    // MARK: Cert generation
    case generateCert(ConnectionType, String, String, String, String)
    case finishGenerateCert

    // MARK: Key Pair generation
    case generateKeyId
    case generateKeyPair(ConnectionType, String, String, String)
    case finishGenerateKeyPair
    case updateKeys([KeyModel])

    // MARK: Reading certs from token
    case readCerts(RtTokenType, String)
    case updateCerts([CertModel])
    case selectCert(CertModel)

    // MARK: User handling
    case removeUser(BankUser)
    case selectUser(BankUser?)
    case updateUsers([BankUser])

    // MARK: Other
    case openLink(LinkType)

    // MARK: PIN operations
    case savePin(String, String, Bool)
    case getPin(String)
    case updatePin(String?)
    case deletePin(String)

    // MARK: NFC interactions
    case lockNfc
    case willUnlockNfc
    case unlockNfc
}
