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
    let timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()

    @Binding var startToClose: Bool
    @Binding var isPressed: Bool

    @State var isDisabled: Bool

    init(user: BankUserInfo, startToClose: Binding<Bool>, isPressed: Binding<Bool>) {
        self.user = user
        self._isDisabled = State(initialValue: user.isDisabled)
        self._startToClose = startToClose
        self._isPressed = isPressed
    }

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
                .opacity(isDisabled ? 0.4 : 1)
                if isDisabled {
                    Text("Сертификат истек")
                        .font(.subheadline)
                        .foregroundStyle(Color.RtColors.rtColorsSystemRed)
                }
            }
            .padding(12)
            Spacer()
        }
        .background(isPressed ? Color.RtColors.rtOtherSelected : Color("surfacePrimary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onReceive(timer) { _ in
            isDisabled = user.isDisabled
            if isDisabled {
                self.timer.upstream.connect().cancel()
            }
        }
    }

    private func infoField(for title: String, with value: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
            Text(value ?? "Не задано")
                .font(.subheadline)
                .foregroundStyle(value != nil ? Color.RtColors.rtLabelPrimary : Color.labelTertiary)
        }
    }
}

struct UserListItem_Previews: PreviewProvider {
    static var previews: some View {
        let user = BankUserInfo(expiryDate: Date().addingTimeInterval(-5 * 60),
                                fullname: "Иванов Михаил Романович",
                                title: "Дизайнер", keyId: "",
                                certHash: "", tokenSerial: "")
        let expiredUser = BankUserInfo(expiryDate: Date().addingTimeInterval(3),
                                fullname: "Иванов Михаил Романович",
                                title: "Дизайнер", keyId: "",
                                certHash: "", tokenSerial: "")
        List {
            UserListItem(user: user, startToClose: .constant(false), isPressed: .constant(false))
                .padding(15)
                .background(Color.RtColors.rtSurfaceSecondary)
            UserListItem(user: expiredUser, startToClose: .constant(false), isPressed: .constant(false))
                .padding(15)
                .background(Color.RtColors.rtSurfaceSecondary)
        }
    }
}
