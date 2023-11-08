//
//  IphoneRootView.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 26.10.2023.
//

import SwiftUI

import TinyAsyncRedux


struct IphoneRootView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>
    @Binding var selectedTab: RtAppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(RtAppTab.allCases, id: \.rawValue) { tab in
                switch tab {
                case .ca:
                    CaEntryView()
                        .tabItem { Label(tab.rawValue, systemImage: tab.imageName) }
                        .tag(tab)
                        .background {
                            Color("surfaceSecondary")
                                .ignoresSafeArea()
                        }
                default:
                    Text(tab.rawValue)
                        .tabItem { Label(tab.rawValue, systemImage: tab.imageName) }
                        .tag(tab)
                }
            }
        }
        .tint(Color("colorsSecondary"))
    }
}

struct IphoneRootView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store(initialState: AppState(),
                          reducer: AppReducer(),
                          middlewares: [])
        IphoneRootView(selectedTab: .constant(.ca))
            .environmentObject(store)
    }
}
