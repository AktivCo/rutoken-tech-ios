//
//  ScrollViewOffset.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 25.01.2024.
//

import SwiftUI


struct ScrollViewOffset<Content: View>: View {
    let content: () -> Content
    let onOffsetChanged: (CGFloat) -> Void
    private let scrollCoordinateSpace = "scrollCoordinateSpace"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                offsetReader
                content()
            }
        }
        .coordinateSpace(name: scrollCoordinateSpace)
        .onPreferenceChange(OffsetPreferenceKey.self, perform: onOffsetChanged)
    }

    private var offsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: OffsetPreferenceKey.self,
                    value: proxy.frame(in: .named(scrollCoordinateSpace)).minY
                )
        }
        .frame(height: 0)
    }
}

private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}
