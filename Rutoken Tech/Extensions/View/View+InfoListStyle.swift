//
//  View+InfoListStyle.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 05.02.2024.
//

import SwiftUI


private struct InfoListStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color("surfacePrimary"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func infoListStyle() -> some View {
        modifier(
            InfoListStyle()
        )
    }
}
