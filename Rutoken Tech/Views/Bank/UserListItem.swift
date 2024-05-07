//
//  UserListItem.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 19.02.2024.
//

import SwiftUI


struct UserListItem: View {
    @State private var offset = 0.0
    private let maxTranslation = -80.0

    let name: String
    let title: String
    let expiryDate: Date

    let onDeleteUser: (() -> Void)
    let onSelectUser: (() -> Void)
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(Color.RtColors.rtLabelPrimary)
                VStack(alignment: .leading, spacing: 8) {
                    infoField(for: "Должность", with: title)
                    infoField(for: "Сертификат истекает", with: expiryDate.getString(as: "dd.MM.yyyy"))
                }
            }
            Spacer()
        }
        .padding(.all, 12)
        .background(Color("surfacePrimary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            if offset == 0.0 {
                onSelectUser()
            } else {
                withAnimation {
                    offset = 0.0
                }
            }
        }
        .offset(x: offset)
        .gesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .local)
                .onChanged {
                    let translation = $0.translation.width
                    withAnimation {
                        if translation < 0 {
                            offset = max(translation, maxTranslation)
                        } else {
                            offset = 0
                        }
                    }
                }
                .onEnded {
                    let translation = $0.translation.width
                    withAnimation {
                        if translation < maxTranslation / 2 {
                            offset = maxTranslation
                        } else {
                            offset = 0
                        }
                    }
                }
        )
        .background(deleteButton)
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

    private var deleteButton: some View {
        HStack {
            Spacer()
            Button {
                onDeleteUser()
            } label: {
                VStack {
                    Spacer()
                    Image(systemName: "trash.fill")
                        .foregroundStyle(Color.RtColors.rtColorsOnPrimary)
                        .frame(width: 72)
                    Spacer()
                }
                .background(Color.RtColors.rtColorsSystemRed)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding([.trailing, .vertical], 1)
        }
    }
}


struct UserListItem_Previews: PreviewProvider {
    static var previews: some View {
        let user = BankUserInfo(expiryDate: Date(), fullname: "Иванов Михаил Романович",
                                title: "Дизайнер", keyId: "", certHash: "", tokenSerial: "")
        UserListItem(name: user.fullname, title: user.title, expiryDate: user.expiryDate,
                     onDeleteUser: {}, onSelectUser: {})
        .padding(15)
        .background(Color.RtColors.rtSurfaceSecondary)
    }
}
