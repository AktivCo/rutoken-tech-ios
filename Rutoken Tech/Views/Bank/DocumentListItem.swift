//
//  DocumentListItem.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 22.03.2024.
//

import SwiftUI

import TinyAsyncRedux


struct DocumentListItem: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>
    let document: BankDocument

    var body: some View {
        Button {
            store.send(.selectDocument(document))
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: document.action.getImageName)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .foregroundStyle(Color.RtColors.rtColorsOnPrimary)
                    .frame(width: 32, height: 32)
                    .background(
                        document.direction == .income
                        ? Color.RtColors.rtColorsSecondary
                        : Color.RtColors.rtColorsPrimary100
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(document.amount) ₽")
                        .font(.headline)
                        .foregroundStyle(Color.RtColors.rtLabelPrimary)
                    Group {
                        Text(document.name.withoutPathExtension)
                        Text(document.companyName)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.RtColors.rtLabelSecondary)
                }
                Spacer()
            }
            .padding(12)
        }
        .background(Color("surfacePrimary"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


struct DocumentListItem_Previews: PreviewProvider {
    static var previews: some View {
        let date = Date(timeIntervalSince1970: 1720000000)
        Group {
            DocumentListItem(document: BankDocument(
                name: "Платежное поручение №121", action: .verify, amount: 14500,
                companyName: "ОАО “Нефтегаз”", paymentTime: date))

            DocumentListItem(document: BankDocument(
                name: "Платежное поручение №121", action: .sign, amount: 14500,
                companyName: "ОАО “Нефтегаз”", paymentTime: date))
        }
        .padding(15)
        .background(Color.RtColors.rtSurfaceSecondary)
    }
}
