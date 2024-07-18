//
//  VcrInfoListItem.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 19.07.2024.
//

import SwiftUI


struct VcrInfoListItem: View {
    let vcrInfo: VcrInfo
    @Binding var startToClose: Bool
    @Binding var isPressed: Bool

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "creditcard")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(Color.RtColors.rtColorsSecondary)
                .frame(width: 28, height: 28)
                .padding(.trailing, 10)
            Text(vcrInfo.name)
                .lineLimit(1)
                .foregroundStyle(Color.RtColors.rtLabelPrimary)
            Spacer()
            Text(vcrInfo.isActive ? "Подключен" : "Не подключен")
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
                .lineLimit(1)
                .frame(width: vcrInfo.isActive ? 92 : 116)
        }
        .frame(height: startToClose ? 0 : 44)
        .padding(.horizontal, 8)
        .background(isPressed ? Color.RtColors.rtOtherSelected : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.leading, 16)
    }
}

struct VcrInfoListItem_Previews: PreviewProvider {
    static var previews: some View {
        VcrInfoListItem(vcrInfo: VcrInfo(id: Data(), name: "ivan", isActive: true), startToClose: .constant(false), isPressed: .constant(false))
            .padding(15)
            .background(Color.RtColors.rtSurfaceSecondary)
            .frame(width: 360)
    }
}
