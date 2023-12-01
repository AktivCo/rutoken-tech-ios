//
//  AppAction.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 22.11.2023.
//

import RtUiComponents


enum AppAction {
    // MARK: Errors and Alerts
    case showAlert(AppAlert)
    case hideAlert
    case showSheet(SheetData)
    case hideSheet
    case showPinInputError(String)
    case hidePinInputError

    // MARK: Token Selection
    case selectToken(RtTokenType, String)
    case tokenSelected(TokenInfo)
}
