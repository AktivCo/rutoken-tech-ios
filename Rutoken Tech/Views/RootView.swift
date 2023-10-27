//
//  RootView.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2023-09-29.
//

import SwiftUI


struct RootView: View {
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
        RootView()
    }
}
