//
//  TokenInteractionState.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 23.05.2024.
//

enum TokenInteractionState: Equatable {
    case ready
    case inProgress
    case cooldown(UInt)
}
