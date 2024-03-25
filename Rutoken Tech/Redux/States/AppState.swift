//
//  AppState.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 22.11.2023.
//


struct AppState {
    // MARK: Common
    var routingState = RoutingState()
    // MARK: Ca
    var connectedTokenState = ConnectedTokenState()
    var caGenerateKeyPairState = CaGenerateKeyPairState()
    var caGenerateCertState = CaGenerateCertState()
    // MARK: Bank
    var bankSelectUserState = BankSelectUsersState()
    var bankCertListState = BankCertListState()
    var bankDocumentListState = BankDocumentListState()
    // MARK: NFC
    var nfcState = NfcState()
}
