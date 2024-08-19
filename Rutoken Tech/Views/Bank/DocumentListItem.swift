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
            if UIDevice.isPhone { store.send(.showFullCoverView) }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                docImage()
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

    private func docImage() -> some View {
        var imageName: String
        var badgeImageName: String?
        var badgeColor: Color?

        switch (document.action, document.signStatus) {
        case (.encrypt, _):
            imageName = "lock.fill"
        case (.decrypt, _):
            imageName = "doc.plaintext.fill"
        case (.sign, _):
            imageName = "pencil"
        case (.verify, .ok):
            imageName = "doc.text.fill"
        case (.verify, .brokenChain):
            imageName = "doc.fill"
            badgeImageName = "questionmark.circle.fill"
            badgeColor = .orange
        case (.verify, .invalid):
            imageName = "doc.fill"
            badgeImageName = "exclamationmark.circle.fill"
            badgeColor = .red
        }

        return Image(systemName: imageName)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: 18, height: 18)
            .foregroundStyle(Color.RtColors.rtColorsOnPrimary)
            .frame(width: 32, height: 32)
            .badgeStyle(imageName: badgeImageName, color: badgeColor)
            .background(
                document.direction == .income
                ? Color.RtColors.rtColorsSecondary
                : Color.RtColors.rtColorsPrimary100
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct AddImageBadge: ViewModifier {
    let image: Image
    let color: Color
    func body(content: Content) -> some View {
        ZStack(alignment: .bottomLeading) {
            content
            Circle().frame(width: 14, height: 14)
                .padding(.bottom, 3)
                .padding(.leading, 3)
                .blendMode(.destinationOut)
            image
                .resizable()
                .foregroundStyle(.white, color)
                .frame(width: 12, height: 12)
                .padding(.bottom, 4)
                .padding(.leading, 4)
        }
        .compositingGroup()
    }
}

private extension View {
    func badgeStyle(imageName: String?, color: Color?) -> some View {
        if let imageName, let color {
            return AnyView(modifier(
                AddImageBadge(image: Image(systemName: imageName),
                              color: color)
            ))
        } else {
            return AnyView(self)
        }
    }
}

struct DocumentListItem_Previews: PreviewProvider {
    static var previews: some View {
        let date = Date(timeIntervalSince1970: 1720000000)
        VStack {
            DocumentListItem(document: BankDocument(
                name: "Платежное поручение №121", action: .verify, amount: 14500,
                companyName: "ОАО “Нефтегаз”", paymentTime: date, signStatus: .brokenChain))
            DocumentListItem(document: BankDocument(
                name: "Платежное поручение №121", action: .verify, amount: 14500,
                companyName: "ОАО “Нефтегаз”", paymentTime: date, signStatus: .invalid))
            DocumentListItem(document: BankDocument(
                name: "Платежное поручение №121", action: .sign, amount: 14500,
                companyName: "ОАО “Нефтегаз”", paymentTime: date))
        }
        .environmentObject(Store(initialState: AppState(), reducer: AppReducer(), middlewares: []))
        .padding(15)
        .background(Color.RtColors.rtSurfaceSecondary)
    }
}
