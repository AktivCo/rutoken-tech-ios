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

    // MARK: Other
    case openLink(LinkType)
}
