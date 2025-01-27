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
    case showSheet(Bool, RtSheetSize, any View, Bool = false)
    case hideSheet
    case hideVcrView
    case showPinInputError(String)
    case hidePinInputError
    case updateActionWithTokenButtonState(RtContinueButtonState)
    case handleError(Error?, [AppAction] = [])
    case showFullCoverView
    case hideFullCoverView

    // MARK: Initialization
    case appLoaded

    // MARK: Token Selection
    case selectToken(RtTokenType, String)
    case tokenSelected(TokenInfo, String)
    case logout

    // MARK: Cert generation
    case generateCert(ConnectionType, serial: String, pin: String, id: Data, commonName: String)

    // MARK: Key Pair generation
    case generateKeyId
    case generateKeyPair(ConnectionType, serial: String, pin: String, id: Data)
    case updateKeys([KeyModel])

    // MARK: Reading certs from token
    case readCerts(RtTokenType, String)
    case cacheCaCerts([CertMetaData])
    case updateBankCerts([CertViewData])
    case selectCert(CertViewData)

    // MARK: User handling
    case selectUser(BankUserInfo?)
    case deleteUser(BankUserInfo)
    case authUser(RtTokenType, String, BankUserInfo)
    case prepareDocuments(Data)
    case updateUsers([BankUserInfo])

    // MARK: Other
    case openLink(LinkType)

    // MARK: PIN operations
    case savePin(String, String, Bool)
    case getPin(String)
    case updatePin(String)
    case deletePin(String)

    // MARK: Bank Documents
    case resetDocuments
    case updateDocuments([BankDocument])

    // MARK: Bank crypto operations
    case signDocument(tokenType: RtTokenType, serial: String, pin: String, documentName: String, certId: Data)
    case cmsVerify(documentName: String)
    case encryptDocument(documentName: String)
    case decryptCms(tokenType: RtTokenType, serial: String, pin: String, documentName: String, certId: Data)
    case selectDocument(BankDocument)
    case updateCurrentDoc(BankDocument?, BankFileContent?)
    case updateUrlsForShare([URL])

    // MARK: VCR operations
    case generateQrCode
    case invalidateQrCodeTimer
    case updateQrCode(Image?)
    case updateQrCodeCountdown(QrCodeTimerState)
    case updateVcrList([VcrInfo])
    case showVcrIndicator
    case hideVcrIndicator
    case unpairVcr(Data)
}
