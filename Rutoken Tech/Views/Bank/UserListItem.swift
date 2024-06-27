//
//  UserListItem.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 19.02.2024.
//

import SwiftUI

import RtUiComponents


struct UserListItem: View {
    let user: BankUserInfo
    @Binding var startToClose: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(user.fullname)
                    .font(.headline)
                    .foregroundStyle(Color.RtColors.rtLabelPrimary)
                VStack(alignment: .leading, spacing: 8) {
                    infoField(for: "Должность", with: user.title)
                    infoField(for: "Сертификат истекает", with: user.expiryDate.getString(as: "dd.MM.yyyy"))
                }
            }
            .padding(12)
            Spacer()
        }
        .frame(maxHeight: startToClose ? 0 : 152)
        .background(Color("surfacePrimary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func infoField(for title: String, with value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.RtColors.rtLabelPrimary)
        }
    }
}


struct UserListItem_Previews: PreviewProvider {
    static var previews: some View {
        let user = BankUserInfo(expiryDate: Date(), fullname: "Иванов Михаил Романович",
                                title: "Дизайнер", keyId: "", certHash: "", tokenSerial: "")
        UserListItem(user: user, startToClose: .constant(false))
            .padding(15)
            .background(Color.RtColors.rtSurfaceSecondary)
    }
}
