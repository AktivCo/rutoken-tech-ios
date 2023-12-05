//
//  AppReducer.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 22.11.2023.
//

import TinyAsyncRedux


struct AppReducer: Reducer {
    func reduce(state: AppState, withAction action: AppAction) -> AppState {
        var newState = state
        switch action {
        case .hideAlert:
            newState.routingState.alert = nil
        case let .showAlert(appAlert):
            newState.routingState.alert = appAlert.alertModel
        }
        return newState
    }
}
