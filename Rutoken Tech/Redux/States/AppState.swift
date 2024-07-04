//
//  AppState.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 22.11.2023.
//


struct AppState {
    // MARK: Common
    var routingState = RoutingState()
    var vcrState = VcrState()
    // MARK: Ca
    var caConnectedTokenState = CaConnectedTokenState()
    var caGenerateKeyPairState = CaGenerateKeyPairState()
    var caGenerateCertState = CaGenerateCertState()
    // MARK: Bank
    var bankSelectUserState = BankSelectUsersState()
    var bankCertListState = BankCertListState()
    var bankDocumentListState = BankDocumentListState()
    var bankSelectedDocumentState = BankSelectedDocumentState()
}
