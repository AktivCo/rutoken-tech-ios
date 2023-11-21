//
//  TokenInfo.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//

struct TokenInfo: Equatable {
    let label: String
    let serial: String
    let model: TokenModel
    let supportedInterfaces: Set<TokenInterface>
}
