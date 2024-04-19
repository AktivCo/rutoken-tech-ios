//
//  DocumentProcessView.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 11.04.2024.
//

import SwiftUI

import TinyAsyncRedux


struct DocumentProcessView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>

    private var backButtonLabel: some View {
        Image(systemName: "chevron.backward")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 19)
            .foregroundStyle(Color.RtColors.rtColorsSecondary)
    }

    private var shareButtonLabel: some View {
        Image(systemName: "square.and.arrow.up")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 25)
            .foregroundStyle(Color.RtColors.rtColorsSecondary)
    }

    private func mainTitle(_ title: String, _ date: String) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.subheadline)
                .bold()
                .frame(height: 20)
                .foregroundColor(Color.RtColors.rtLabelPrimary)
            Text(date)
                .font(.caption)
                .frame(height: 16)
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
        }
    }

    private func navBar(title: String, date: String) -> some View {
        CustomNavBar {
            Button {
            } label: {
                backButtonLabel
                    .padding(.leading, 13)
                Spacer()
            }
            .frame(maxHeight: .infinity)
            .frame(width: 44)
        } center: {
            mainTitle(title, date)
        } right: {
            Button {
            } label: {
                shareButtonLabel
                    .padding(.trailing, 19)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 44)
        .background(Color("IOSElementsTitleBarSurface"))
    }

    private func bottomBar(action: @escaping () -> Void) -> some View {
        var title: String {
            switch store.state.bankSelectedDocumentState.metadata?.action {
            case .decrypt: "Расшифровать"
            case .encrypt: "Зашифровать"
            case .sign: "Подписать"
            case .verify: "Проверить подпись"
            case .none: ""
            }
        }
        return VStack(spacing: 0) {
            Button {
                action()
            } label: {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Color.RtColors.rtColorsSecondary)
            }
        }
        .frame(height: 49)
        .frame(maxWidth: .infinity)
        .background(Color("IOSElementsTitleBarSurface"))
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar(title: store.state.bankSelectedDocumentState.metadata?.name ?? "",
                   date: store.state.bankSelectedDocumentState.metadata?.paymentDay.getRussianStringWithTime ?? "")

            switch store.state.bankSelectedDocumentState.docContent {
            case .pdfDoc(let pdf):
                RtPDFView(pdf: pdf)
            case .base64(let str):
                VStack {
                    Text(str)
                        .font(.caption)
                        .padding(12)
                        .frame(width: UIDevice.isPhone ? 350 : 437,
                               height: UIDevice.isPhone ? 495 : 618)
                        .background(Color.RtColors.rtColorsOnPrimary)
                        .foregroundColor(Color("alwaysBlack"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("otherSeparator"), lineWidth: 0.5)
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.RtColors.rtSurfaceSecondary)
            case .none:
                EmptyView()
            }

            bottomBar {
            }
        }
    }
}

struct DocumentProcessView_Previews: PreviewProvider {
    static var previews: some View {
        let metadata = BankDocument(
            name: "Платежное поручение №00121", action: .encrypt, amount: 14500,
            companyName: "ОАО “Нефтегаз”", paymentDay: Date(timeIntervalSince1970: 1720000000))
        let url = Bundle.main.url(forResource: metadata.name, withExtension: ".pdf", subdirectory: "BankDocuments")!
        let data = try? Data(contentsOf: url)
        let content = BankFileContent(type: .plain, content: data!)

        let doc = BankSelectedDocumentState(metadata: metadata, docContent: content)
        let state = AppState(bankSelectedDocumentState: doc)
        let store = Store(initialState: state, reducer: AppReducer(), middlewares: [])

        DocumentProcessView().environmentObject(store)

        let encrypted = """
MIIDrTCCA1ygAwIBAgIKc522PB4SUNntVzAIBgYqhQMCAgMwgbMxCzAJBgNVBAYTAlJVMSAwHgYDVQQK
DBfQn9CQ0J4g0KHQsdC10YDQsdCw0L3QujE4MDYGA1UECwwv0JTQtdC/0LDRgNGC0LDQvNC10L3RgiDQ
sdC10LfQvtC/0LDRgdC90L7RgdGC0LgxJTAjBgNVBAMMHNCj0KYg0J/QkNCeINCh0LHQtdGA0LHQsNC9
0LoxITAfBgkqhkiG9w0BCQEWEmNhc2JyZkBzYmVyYmFuay5ydTAeFw0xNTEwMjcxMzM1NDhaFw0yMTEw
MjcxMzM1NDhaMIHOMQswCQYDVQQGEwJSVTEgMB4GA1UECgwX0J/QkNCeINCh0LHQtdGA0LHQsNC90Lox
ODA2BgNVBAsML9CU0LXQv9Cw0YDRgtCw0LzQtdC90YIg0LHQtdC30L7Qv9Cw0YHQvdC+0YHRgtC4MSUw
IwYDVQQDDBzQo9CmINCf0JDQniDQodCx0LXRgNCx0LDQvdC6MRkwFwYDVQQHDBDQsy4g0JzQvtGB0LrQ
stCwMSEwHwYJKoZIhvcNAQkBFhJjYXNicmZAc2JlcmJhbmsucnUwYzAcBgYqhQMCAhMwEgYHKoUDAgIj
AgYHKoUDAgIeAQNDAARAGqhivXMztAg8AH1j/zCA9793+ZS6ylc7NjT1OkdEXn6BL6aLAvFhlZPSuOK3
pJtYZL/hqvFivmCKLYUBOvioSaOCATEwggEtMA8GA1UdEwEB/wQFMAMBAf8wGAYDVR0lBBEwDwYEVR0l
AAYHKoUDA3sFATAOBgNVHQ8BAf8EBAMCAcYwNwYDVR0fBDAwLjAsoCqgKIYmaHR0cDovL3d3dy5zYmVy
YmFuay5ydS9jYS8wMDAweDUwOS5jcmwwQQYHKoUDA3sDAQQ2DDQwMENBMlRIWnHQodC10YDQstC10YDQ
rdCfINCj0KbQn9CQ0J7QodCx0LXRgNCx0LDQvdC6MBUGByqFAwN7AwYECgwIMDAwMzI4NjMwHQYFKoUD
ZG8EFAwS0JHQuNC60YDQuNC/0YIgNC4wMB0GA1UdDgQWBBTK4sdjgF7LxlY0hE9+PGfGBoVgWzAfBgNV
HSMEGDAWgBSxxaus16nX5k5kZWSLi+MLfUFW6zAIBgYqhQMCAgMDQQAP/xbKrJr7s9jhvcM7Kzn3mPbZ
DNlcZpAMfyH2LzoOPDwtMxnVEDeow7W6OsDouUDP5yB8Cqy7f2GMBU5C7cAi
"""
        let encryptedContent = BankFileContent(type: .encrypted, content: encrypted.data(using: .utf8)!)
        let encryptMetadata = BankDocument(
            name: "Платежное поручение №00121", action: .decrypt, amount: 14500,
            companyName: "ОАО “Нефтегаз”", paymentDay: Date(timeIntervalSince1970: 1720000000))

        let encryptedDoc = BankSelectedDocumentState(metadata: encryptMetadata, docContent: encryptedContent!)
        let stateForEncrypted = AppState(bankSelectedDocumentState: encryptedDoc)
        let storeForEncrypted = Store(initialState: stateForEncrypted, reducer: AppReducer(), middlewares: [])

        DocumentProcessView().environmentObject(storeForEncrypted)
    }
}