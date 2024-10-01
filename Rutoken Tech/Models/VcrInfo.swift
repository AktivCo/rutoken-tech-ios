//
//  VcrInfo.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 05.07.2024.
//

import Foundation

import RtUiComponents


struct VcrInfo: RtListItem {
    let id: Data
    let name: String
    let isActive: Bool

    var state: RtListItemState {
        isActive ? .disableSwipe : .normal
    }
}
