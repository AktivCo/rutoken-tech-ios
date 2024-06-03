//
//  CaConnectedTokenState.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 20.11.2023.
//


struct CaConnectedTokenState {
    var connectedToken: TokenInfo?
    var certs: [CertMetaData] = []
    var pin: String?
}
