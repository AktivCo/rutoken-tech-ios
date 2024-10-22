//
//  AppState.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 22.11.2023.
//


struct AppState {
    var connectedTokenState = ConnectedTokenState()
    var routingState = RoutingState()
    var caGenerateKeyPairState = CaGenerateKeyPairState()
    var caGenerateCertState = CaGenerateCertState()
    var nfcState = NfcState()
}
