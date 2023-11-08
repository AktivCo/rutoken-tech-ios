//
//  RootView.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2023-09-29.
//

import SwiftUI

import TinyAsyncRedux


struct RootView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>
    @State private var selectedTab: RtAppTab = .ca

    var body: some View {
        if UIDevice.isPhone {
            IphoneRootView(selectedTab: $selectedTab)
        } else {
            IpadRootView()
        }
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
