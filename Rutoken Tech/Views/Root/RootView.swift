//
//  RootView.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2023-09-29.
//

import SwiftUI

import TinyAsyncRedux

import RtUiComponents


struct RootView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>

    var body: some View {
        VStack {
            if UIDevice.isPhone {
                IphoneRootView()
            } else {
                IpadRootView()
            }
        }
        .rtSheet(sheetModel: store.state.routingState.sheet)
        .rtAlert(alertModel: Binding(get: { store.state.routingState.alert },
                                     set: { if $0 == nil { store.send(.hideAlert) } }))
        .rtVcrIndicator(Binding(get: { store.state.vcrState.vcrNameInProgress }, set: { _ in }))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store(initialState: AppState(),
                          reducer: AppReducer(),
                          middlewares: [])
        RootView()
            .environmentObject(store)
    }
}
