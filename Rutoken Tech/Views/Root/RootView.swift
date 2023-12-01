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
    @State private var selectedTab: RtAppTab = .ca

    var body: some View {
        VStack {
            if UIDevice.isPhone {
                IphoneRootView(selectedTab: $selectedTab)
            } else {
                IpadRootView()
            }
        }
        .rtSheet(isPresented: Binding(
            get: { store.state.routingState.sheet != nil },
            set: { newValue in
                if !newValue {
                    store.send(.hideSheet)
                }
            }),
                 size: store.state.routingState.sheet?.size ?? .largePhone,
                 isDraggable: store.state.routingState.sheet?.isDraggable ?? true) {
            store.state.routingState.sheet?.content ?? AnyView(EmptyView())
        }
        .rtAlert(isPresented: Binding(
            get: { store.state.routingState.alert != nil },
            set: { newValue in
                if !newValue {
                    store.send(.hideAlert)
                }
            }),
                 alertData: store.state.routingState.alert ?? AppAlert.unknownError.alertModel
        )
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
