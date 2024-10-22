//
//  RoutingState.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 29.11.2023.
//

import Foundation

import RtUiComponents


struct RoutingState {
    var alert: RtAlertModel?
    var sheet: RtSheetModel = RtSheetModel(size: .largePhone, isDraggable: false)
    let pinInputModel = RtPinInputModel()
}
