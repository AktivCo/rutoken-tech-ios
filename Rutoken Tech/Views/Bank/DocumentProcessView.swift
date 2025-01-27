//
//  DocumentProcessView.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 11.04.2024.
//

import PDFKit
import SwiftUI

import RtUiComponents
import TinyAsyncRedux


struct DocumentProcessView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>

    @State private var topSafeAreaHeight: CGFloat = getSafeAreaInsets()?.top ?? 0
    @State private var bottomSafeAreaHeight: CGFloat = UIDevice.isPhone ? (getSafeAreaInsets()?.bottom ?? 0) : 0
    @State private var navBarSize: CGSize = .zero
    @State private var bottomBarSize: CGSize = .zero
    @State private var wholeViewSize: CGSize = .zero

    private var displayContentHeight: Double {
        max(wholeViewSize.height - bottomBarSize.height - navBarSize.height, 0)
    }

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

    private func shareButton(urls: [URL]) -> some View {
        ShareLink(items: urls) {
            shareButtonLabel
                .padding(.trailing, 19)
        }
    }

    private func navBar(title: String, date: String) -> some View {
        VStack(spacing: 0) {
            CustomNavBar {
                Button {
                    if UIDevice.isPhone {
                        store.send(.hideFullCoverView)
                    } else {
                        store.send(.updateCurrentDoc(nil, nil))
                    }
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
                shareButton(urls: store.state.bankSelectedDocumentState.urlsForShare)
            }
            .frame(height: 44)
            .padding(.top, topSafeAreaHeight)
            .background(Color("IOSElementsTitleBarSurface"))
            Divider()
                .overlay(Color("IOSElementsTitleBarSeparator"))
        }
    }

    private func showAuthSheet(_ callback: @escaping (RtTokenType, String, String, String, Data) -> Void) {
        guard store.state.bankSelectedDocumentState.metadata?.inArchive == false,
              let tokenSerial = store.state.bankSelectUserState.selectedUser?.tokenSerial,
              let certId = store.state.bankSelectUserState.selectedUser?.keyId,
              let fileName = store.state.bankSelectedDocumentState.metadata?.name else {
            store.send(.showAlert(.unknownError))
            return
        }

        store.send(.showSheet(false, UIDevice.isPhone ? .largePhone : .ipad(width: 540, height: 640), {
            RtAuthView(defaultPinGetter: { store.send(.getPin(tokenSerial)) },
                       onSubmit: { tokenType, pin in callback(tokenType, tokenSerial, pin, fileName, certId) },
                       onCancel: {
                store.send(.hideSheet)
                store.send(.updatePin(""))
            })
            .environmentObject(store.state.routingState.pinInputModel)
        }()))
    }

    private func actionButton(for action: BankDocument.ActionType) -> some View {
        var title: String {
            switch action {
            case .decrypt: "Расшифровать"
            case .encrypt: "Зашифровать"
            case .sign: "Подписать"
            case .verify: "Проверить подпись"
            }
        }

        return Button {
            guard let document = store.state.bankSelectedDocumentState.metadata else {
                return
            }
            switch document.action {
            case .decrypt:
                showAuthSheet { tokenType, tokenSerial, pin, fileName, certId in
                    store.send(.decryptCms(tokenType: tokenType, serial: tokenSerial, pin: pin,
                                           documentName: fileName, certId: certId))
                }
            case .encrypt:
                store.send(.encryptDocument(documentName: document.name))
            case .sign:
                showAuthSheet { tokenType, tokenSerial, pin, fileName, certId in
                    store.send(.signDocument(tokenType: tokenType, serial: tokenSerial, pin: pin,
                                           documentName: fileName, certId: certId))
                }
            case .verify:
                store.send(.cmsVerify(documentName: document.name))
            }
        } label: {
            Text(title)
                .font(.body)
                .foregroundStyle(Color.RtColors.rtColorsSecondary)
        }
    }

    private func bottomBar() -> some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color("IOSElementsTitleBarSeparator"))
            Group {
                if let doc = store.state.bankSelectedDocumentState.metadata {
                    var completedActionText: String {
                        switch doc.action {
                        case .decrypt: "Расшифрован"
                        case .encrypt: "Зашифрован"
                        case .sign: "Подписан"
                        case .verify: "Подпись проверена"
                        }
                    }
                    if doc.inArchive {
                        Text("\(completedActionText) \(doc.dateOfChange?.getString(as: "d MMMM yyyy 'г. в' HH:mm") ?? "")")
                            .font(.footnote)
                            .foregroundStyle(Color.RtColors.rtLabelSecondary)
                    } else {
                        actionButton(for: doc.action)
                    }
                } else {
                    Spacer()
                }
            }
            .frame(height: 49)
            .frame(maxWidth: .infinity)
            .padding(.bottom, bottomSafeAreaHeight)
            .background(Color("IOSElementsTitleBarSurface"))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar(title: String(store.state.bankSelectedDocumentState.metadata?.name.split(separator: ".").first ?? ""),
                   date: store.state.bankSelectedDocumentState.metadata?.paymentTime.getString(as: "d MMMM yyyy 'г. в' HH:mm") ?? "")
            .rtSizeReader(size: $navBarSize)
            displayContent(isRtPDFViewShown ? .pdf(store.state.bankSelectedDocumentState.docContent?.data ?? Data()) :
                    .text(store.state.bankSelectedDocumentState.docContent?.data.base64EncodedString() ?? ""))
            bottomBar()
                .rtSizeReader(size: $bottomBarSize)
        }
        .rtSizeReader(size: $wholeViewSize)
        .ignoresSafeArea(.keyboard)
    }

    private enum ContentType {
        case text(String)
        case pdf(Data)
    }

    @ViewBuilder
    private func displayContent(_ content: ContentType) -> some View {
        switch content {
        case .pdf(let data):
            RtPDFView(data: data)
        case .text(let text):
            // ScrollView is needed for keyboard avoidance
            ScrollView {
                Text(text)
                    .font(.caption)
                    .padding(12)
                    .frame(width: UIDevice.isPhone ? 350 : 437,
                           height: UIDevice.isPhone ? 495 : 618, alignment: .top)
                    .background(Color.RtColors.rtColorsOnPrimary)
                    .foregroundColor(Color("alwaysBlack"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("otherSeparator"), lineWidth: 0.5)
                    )
                    .frame(width: wholeViewSize.width, height: displayContentHeight)
                    .background(Color.RtColors.rtSurfaceSecondary)
            }
            .scrollDisabled(true)
        }
    }

    private var isRtPDFViewShown: Bool {
        let action = store.state.bankSelectedDocumentState.metadata?.action
        let inArchive = store.state.bankSelectedDocumentState.metadata?.inArchive ?? false
        return !(action == .decrypt && !inArchive || action == .encrypt && inArchive)
    }
}

struct DocumentProcessView_Previews: PreviewProvider {
    static var previews: some View {
        let emptyState = AppState()
        let emptyStore = Store(initialState: emptyState,
                                reducer: AppReducer(), middlewares: [])
        DocumentProcessView()
            .environmentObject(emptyStore)
            .ignoresSafeArea()

        let metadata = BankDocument(
            name: "Платежное поручение №00121", action: .encrypt, amount: 14500,
            companyName: "ОАО “Нефтегаз”", paymentTime: Date(timeIntervalSince1970: 1720000000))
        let url = Bundle.main.url(forResource: metadata.name, withExtension: ".pdf", subdirectory: "BankDocuments")!
        let data = try? Data(contentsOf: url)
        let content = BankFileContent(data: data!)

        let doc = BankSelectedDocumentState(metadata: metadata, docContent: content)
        let state = AppState(bankSelectedDocumentState: doc)
        let store = Store(initialState: state, reducer: AppReducer(), middlewares: [])

        DocumentProcessView()
            .environmentObject(store)
            .ignoresSafeArea()

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

        let encryptMetadata = BankDocument(
            name: "Платежное поручение №00121", action: .decrypt, amount: 14500,
            companyName: "ОАО “Нефтегаз”", paymentTime: Date(timeIntervalSince1970: 1720000000))

        let encryptedDoc = BankSelectedDocumentState(metadata: encryptMetadata,
                                                     docContent: BankFileContent(data: Data(encrypted.utf8)))
        let stateForEncrypted = AppState(bankSelectedDocumentState: encryptedDoc)
        let storeForEncrypted = Store(initialState: stateForEncrypted, reducer: AppReducer(), middlewares: [])

        DocumentProcessView()
            .environmentObject(storeForEncrypted)
            .ignoresSafeArea()
    }
}
