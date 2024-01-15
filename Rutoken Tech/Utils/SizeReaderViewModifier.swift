//
//  SizeReaderViewModifier.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 29.01.2024.
//

import SwiftUI


extension View {
    func sizeReader(
        size: Binding<CGSize>
    ) -> some View {
        modifier(
            SizeReaderModifier(size: size)
        )
    }
}

private struct SizeReaderModifier: ViewModifier {
    @Binding var size: CGSize
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: proxy.size)
                }
            )
            .onPreferenceChange(SizePreferenceKey.self) { preferences in
                self.size = preferences
            }
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: Value = .zero
    static func reduce(value _: inout CGSize, nextValue: () -> CGSize) {}
}
