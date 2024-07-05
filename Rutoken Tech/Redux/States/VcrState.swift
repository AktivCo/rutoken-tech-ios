//
//  VcrState.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 04.07.2024.
//

import SwiftUI


struct VcrState {
    var qrCode: Image?
    var qrCodeTimer = QrCodeTimerState.expired
    var vcrList: [VcrInfo] = []
}
