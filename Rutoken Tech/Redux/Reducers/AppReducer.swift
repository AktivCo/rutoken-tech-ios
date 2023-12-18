//
//  AppReducer.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 22.11.2023.
//

import Foundation

import TinyAsyncRedux


struct AppReducer: Reducer {
    func reduce(state: AppState, withAction action: AppAction) -> AppState {
        var newState = state
        switch action {
        case let .showAlert(appAlert):
            newState.routingState.alert = appAlert.alertModel
        case .hideAlert:
            newState.routingState.alert = nil
        case let .showSheet(sheet):
            newState.routingState.sheet = sheet
        case .hideSheet:
            newState.routingState.sheet = nil
        case .selectToken:
            break
        case let .tokenSelected(info):
            newState.caEntryViewState.connectedToken = info
        case let .showPinInputError(errorText):
            newState.routingState.pinInputError.errorDescription = errorText
        case .hidePinInputError:
            newState.routingState.pinInputError.errorDescription = ""
        case .generateKeyId:
            newState.caGenerateKeyPairSate.key = KeyModel(ckaId: String().generateID(),
                                                          type: .gostR3410_2012_256)
        case .generateKeyPair:
            newState.caGenerateKeyPairSate.inProgress = true
        }
        return newState
    }
}
