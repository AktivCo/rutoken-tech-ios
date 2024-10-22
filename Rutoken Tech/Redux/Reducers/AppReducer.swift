//
//  AppReducer.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 22.11.2023.
//

import Foundation
import SwiftUI

import TinyAsyncRedux


struct AppReducer: Reducer {
    func reduce(state: AppState, withAction action: AppAction) -> AppState {
        var newState = state
        switch action {
        case let .showAlert(appAlert):
            newState.routingState.alert = appAlert.alertModel
        case .hideAlert:
            newState.routingState.alert = nil
        case let .showSheet(draggable, size, content):
            newState.routingState.sheet.isDraggable = draggable
            newState.routingState.sheet.size = size
            newState.routingState.sheet.content = AnyView(content)
            newState.routingState.sheet.isPresented = true
        case .hideSheet:
            newState.routingState.sheet.isPresented = false
        case .selectToken:
            break
        case let .tokenSelected(info, pin):
            newState.connectedTokenState.connectedToken = info
            newState.connectedTokenState.pin = pin
        case let .showPinInputError(errorText):
            newState.routingState.pinInputModel.errorDescription = errorText
        case .hidePinInputError:
            newState.routingState.pinInputModel.errorDescription = ""
        case .generateKeyId:
            newState.caGenerateKeyPairState.key = KeyModel(ckaId: String.generateID(),
                                                           type: .gostR3410_2012_256)
        case .generateKeyPair:
            newState.caGenerateKeyPairState.inProgress = true
            newState.routingState.pinInputModel.inProgress = true
        case .finishGenerateKeyPair:
            newState.caGenerateKeyPairState.inProgress = false
            newState.routingState.pinInputModel.inProgress = false
        case .updateKeys(let keys):
            newState.caGenerateCertState.keys = keys
        case .generateCert:
            newState.caGenerateCertState.inProgress = true
        case .finishGenerateCert:
            newState.caGenerateCertState.inProgress = false
        case .logoutCa:
            newState.connectedTokenState.connectedToken = nil
            newState.connectedTokenState.pin = nil
            newState.caGenerateKeyPairState.inProgress = false
            newState.caGenerateKeyPairState.key = nil
            newState.caGenerateCertState.inProgress = false
            newState.caGenerateCertState.keys = []
        case .openLink:
            break
        case .lockNfc:
            newState.nfcState.isLocked = true
            newState.routingState.pinInputModel.isContinueButtonDisabled = true
        case .unlockNfc:
            newState.nfcState.isLocked = false
            newState.routingState.pinInputModel.isContinueButtonDisabled = false
        case .willUnlockNfc:
            break
        }
        return newState
    }
}
