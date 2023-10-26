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
        if UIDevice.current.userInterfaceIdiom == .phone {
            IphoneRootView(selectedTab: $selectedTab)
        } else {
            Text("Ipad RootView")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
