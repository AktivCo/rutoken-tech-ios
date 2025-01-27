//
//  IphoneRootView.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 26.10.2023.
//

import SwiftUI

import RtUiComponents
import TinyAsyncRedux


struct IphoneRootView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>
    @State var selectedTab: RtAppTab = .ca

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(RtAppTab.allCases, id: \.rawValue) { tab in
                Group {
                    switch tab {
                    case .ca:
                        CaEntryView()
                            .tabItem { Label(tab.rawValue, systemImage: tab.imageName) }
                            .tag(tab)
                            .ignoresSafeArea(.keyboard)
                    case .about:
                        AboutAppView()
                            .tabItem { Label(tab.rawValue, systemImage: tab.imageName) }
                            .tag(tab)
                    case .bank:
                        BankUserListView()
                            .tabItem { Label(tab.rawValue, systemImage: tab.imageName) }
                            .tag(tab)
                    }
                }
                .background {
                    Color.RtColors.rtSurfaceSecondary
                        .ignoresSafeArea()
                }
            }
        }
        .tint(Color.RtColors.rtColorsSecondary)
        .onChange(of: selectedTab) { _ in
            store.send(.logout)
        }
    }
}

struct IphoneRootView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store(initialState: AppState(),
                          reducer: AppReducer(),
                          middlewares: [])
        IphoneRootView()
            .environmentObject(store)
    }
}
