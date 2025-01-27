//
//  View+CustomNavBar.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 27.03.2024.
//

import SwiftUI


struct CustomNavBar<Left, Center, Right>: View where Left: View, Center: View, Right: View {
    let left: () -> Left
    let center: () -> Center
    let right: () -> Right

    init(@ViewBuilder left: @escaping () -> Left,
         @ViewBuilder center: @escaping () -> Center,
         @ViewBuilder right: @escaping () -> Right) {
        self.left = left
        self.center = center
        self.right = right
    }
    var body: some View {
        ZStack {
            HStack {
                left()
                Spacer()
            }
            center()
            HStack {
                Spacer()
                right()
            }
        }
    }
}
