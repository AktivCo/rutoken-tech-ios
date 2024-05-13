//
//  View+createLabel.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 05.02.2024.
//

import SwiftUI


extension View {
    func createLabel(_ label: String, _ value: String) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.body)
                .foregroundStyle(Color.RtColors.rtLabelPrimary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(12)
    }
}
