//
//  IpadRootView.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 26.10.2023.
//

import SwiftUI

import RtUiComponents
import TinyAsyncRedux


struct IpadRootView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>
    @State var selectedTab: RtAppTab? = .ca

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.doubleColumn)) {
            VStack(spacing: 0) {
                Text("Рутокен Технологии").font(.largeTitle).fontWeight(.bold)
                    .foregroundStyle(Color.RtColors.rtLabelPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 24)
                    .padding(.top, 5+44)
                    .padding(.bottom, 12)

                List(RtAppTab.allCases, id: \.self, selection: $selectedTab) { tab in
                    NavigationLink(value: tab) {
                        Label {
                            Text(tab.rawValue)
                                .foregroundStyle(selectedTab == tab ?
                                                 Color.RtColors.rtColorsOnPrimary :
                                                 Color.RtColors.rtLabelPrimary)
                        } icon: {
                            Image(systemName: tab.imageName)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .toolbar(.hidden, for: .navigationBar)
        } detail: {
            if let selectedTab {
                switch selectedTab {
                case .ca:
                    ZStack {
                        Color.RtColors.rtSurfaceSecondary
                            .ignoresSafeArea()
                        VStack(spacing: 0) {
                            CaEntryView()
                        }
                    }
                    .toolbar(.hidden, for: .navigationBar)
                    .ignoresSafeArea(.keyboard)
                default:
                    Text(selectedTab.rawValue)
                        .foregroundStyle(Color.RtColors.rtLabelPrimary)
                        .ignoresSafeArea(.keyboard)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Color.RtColors.rtColorsSecondary)
    }
}

struct IpadRootView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store(initialState: AppState(),
                          reducer: AppReducer(),
                          middlewares: [])
        IpadRootView()
            .environmentObject(store)
    }
}
