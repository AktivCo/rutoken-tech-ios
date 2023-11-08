//
//  Rutoken_TechApp.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2023-09-29.
//

import SwiftUI

import TinyAsyncRedux


@main
struct RutokenTechApp: App {
    let store: Store<AppState, AppAction>

    init() {
        var middlewares: [any Middleware<AppAction>] = []

        store = Store(initialState: AppState(),
                      reducer: AppReducer(),
                      middlewares: middlewares)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
