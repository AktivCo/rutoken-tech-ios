//
//  IpadRootView.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 26.10.2023.
//

import SwiftUI


struct IpadRootView: View {
    @State var selectedTab: RtAppTab? = .ca

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.doubleColumn)) {

            Text("Рутокен Технологии").font(.largeTitle).fontWeight(.bold)
                .foregroundStyle(Color("labelPrimary"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 24)
                .padding(.top, 49)

            List(RtAppTab.allCases, id: \.self, selection: $selectedTab) { tab in
                NavigationLink {
                    Text(tab.rawValue)
                        .foregroundStyle(Color("labelPrimary"))
                } label: {
                    Label(
                        title: {
                            Text(tab.rawValue)
                                .foregroundStyle(selectedTab == tab ?
                                                 Color("colorsOnPrimary") : Color("labelPrimary"))
                        },
                        icon: {
                            Image(systemName: tab.imageName)
                        }
                    )
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            .toolbar(.hidden, for: .navigationBar)
        } detail: {
            if let selectedTab { Text(selectedTab.rawValue) }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Color("colorsSecondary"))
    }
}

struct IpadRootView_Previews: PreviewProvider {
    static var previews: some View {
        IpadRootView()
    }
}
