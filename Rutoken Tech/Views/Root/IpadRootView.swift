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
                .frame(height: 144)
                VStack(spacing: 0) {
                    Text("Виртуальные считыватели").font(.title3).fontWeight(.semibold)
                        .frame(height: 44)
                    RtList(listModel: store.state.vcrState.vcrList)
                    addVcrButton
                    Spacer()
                }
                .padding(.trailing, 16)
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .toolbar(.hidden, for: .navigationBar)
            .background {
                Color("IOSElementsTitleBarSurface")
            }
            .ignoresSafeArea(.container, edges: [.top, .bottom])
        } detail: {
            if let selectedTab {
                Group {
                    VStack(spacing: 0) {
                        switch selectedTab {
                        case .ca:
                            CaEntryView()
                        case .about:
                            AboutAppView()
                        case .bank:
                            BankUserListView()
                        }
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .ignoresSafeArea(.keyboard)
                .background {
                    Color.RtColors.rtSurfaceSecondary
                        .ignoresSafeArea()
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Color.RtColors.rtColorsSecondary)
        .onChange(of: selectedTab) { _ in
            store.send(.logout)
        }
    }

    private var addVcrButton: some View {
        Button {
            store.send(.showSheet(false, .ipad(width: 624, height: 720), {
                VcrView()
                    .environmentObject(store)
            }(), true))
        } label: {
            HStack(spacing: 10) {
                Text(Image(systemName: "plus"))
                    .fontWeight(.semibold)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .frame(width: 28, height: 28)
                            .foregroundStyle(Color.RtColors.rtOtherSelected)
                    )
                    .frame(width: 28, height: 28)
                Text("Добавить")
                    .foregroundStyle(Color.RtColors.rtLabelPrimary)
                Spacer()
            }
            .frame(height: 45)
        }
        .padding(.leading, 24)
    }
}

struct IpadRootView_Previews: PreviewProvider {
    static var previews: some View {
        let state = AppState()
        state.vcrState.vcrList.items = [
            VcrInfo(id: "321".data(using: .utf8)!, name: "Ivan", isActive: false),
            VcrInfo(id: "123".data(using: .utf8)!, name: "Andrey", isActive: true)
        ]
        let store = Store(initialState: state,
                          reducer: AppReducer(),
                          middlewares: [])

        return IpadRootView()
            .environmentObject(store)
    }
}
