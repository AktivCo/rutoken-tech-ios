//
//  HeaderView.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 20.02.2024.
//

import SwiftUI


struct HeaderTitleView: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(Color.RtColors.rtLabelPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 5)
            .padding(.bottom, 12)
    }
}
