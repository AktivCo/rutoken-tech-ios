//
//  TokenInfo.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//

import Foundation


struct TokenInfo: Equatable {
    let label: String?
    let serial: String
    let model: Pkcs11TokenModel
    let connectionType: ConnectionType
    let type: TokenType
}
