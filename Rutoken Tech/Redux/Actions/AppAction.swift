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
    case updateCerts([CertViewData])
    case selectCert(CertViewData)

    // MARK: User handling
    case selectUser(BankUserInfo?)
    case deleteUser(BankUserInfo)
    case authUser(RtTokenType, String, BankUserInfo)
    case prepareDocuments
    case updateUsers([BankUserInfo])

    // MARK: Other
    case openLink(LinkType)

    // MARK: PIN operations
    case savePin(String, String, Bool)
    case getPin(String)
    case updatePin(String)
    case deletePin(String)

    // MARK: NFC interactions
    case lockNfc
    case willUnlockNfc
    case unlockNfc

    // MARK: Bank Documents
    case resetDocuments
    case updateDocuments([BankDocument])
    case signDocument(tokenType: RtTokenType, serial: String, pin: String, documentName: String, certId: String)
}
