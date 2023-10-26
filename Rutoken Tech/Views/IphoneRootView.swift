//
//  IphoneRootView.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 26.10.2023.
//

import SwiftUI


struct IphoneRootView: View {
    @Binding var selectedTab: RtAppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(RtAppTab.allCases, id: \.rawValue) { tab in
                Text(tab.rawValue)
                    .tabItem { Label(tab.rawValue, systemImage: tab.imageName) }
                    .tag(tab)
            }
        }
        .tint(Color("colorsSecondary"))
    }
}

struct IphoneRootView_Previews: PreviewProvider {
    static var previews: some View {
        IphoneRootView(selectedTab: .constant(.ca))
    }
}
