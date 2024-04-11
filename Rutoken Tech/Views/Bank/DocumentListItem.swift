//
//  DocumentListItem.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 22.03.2024.
//

import SwiftUI

import RtUiComponents
import TinyAsyncRedux


struct DocumentListItem: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>
    let document: BankDocument

    var body: some View {
        Button {
            guard document.inArchive == false,
                  let tokenSerial = store.state.bankSelectUserState.selectedUser?.tokenSerial,
                  let certId = store.state.bankSelectUserState.selectedUser?.keyId else {
                return
            }
            store.send(.showSheet(false, UIDevice.isPhone ? .largePhone : .ipad(width: 540, height: 640), {
                RtAuthView(defaultPinGetter: { store.send(.getPin(tokenSerial)) },
                           onSubmit: { tokenType, pin in
                    store.send(.signDocument(tokenType: tokenType, serial: tokenSerial, pin: pin,
                                             documentName: document.name, certId: certId))
                },
                           onCancel: { store.send(.hideSheet) })
                .environmentObject(store.state.routingState.pinInputModel)
            }()))
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
                companyName: "ОАО “Нефтегаз”", paymentDay: date))

            DocumentListItem(document: BankDocument(
                name: "Платежное поручение №121", action: .sign, amount: 14500,
                companyName: "ОАО “Нефтегаз”", paymentDay: date))
        }
        .padding(15)
        .background(Color.RtColors.rtSurfaceSecondary)
    }
}
