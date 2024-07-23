//
//  VcrState.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 04.07.2024.
//

import SwiftUI

import RtUiComponents


struct VcrState {
    var qrCode: Image?
    var qrCodeTimer = QrCodeTimerState.expired
    var vcrList: RtListModel = RtListModel<VcrInfo, VcrInfoListItem>(
        items: [],
        listPadding: 0) { data, startToClose, isPressed in
            VcrInfoListItem(vcrInfo: data, startToClose: startToClose, isPressed: isPressed)
    } onSelect: { _ in } onDelete: { _ in }
    var vcrNameInProgress: String?
}
