//
//  CaCertGenView.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 15.01.2024.
//

import SwiftUI

import RtUiComponents
import TinyAsyncRedux


struct CaCertGenView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>
    @State private var selectedKey: Int = 0
    @State private var nameInput: String = ""
    @GestureState private var dragOffset: CGSize = .zero
    @State private var isTopViewShown = false
    @State private var isBottomViewShown = true
    @State private var inProgress: Bool = false
    @State private var wholeContentSize: CGSize = .zero
    @State private var scrollContentSize: CGSize = .zero

    @State var bottomPadding: CGFloat = UIDevice.isPhone ? 34 : 24

    var body: some View {
        VStack(spacing: 0) {
            certViewHeader
            ScrollViewOffset {
                VStack(alignment: .leading, spacing: 0) {
                    inputTextLabel("ВЫБЕРИТЕ КЛЮЧЕВУЮ ПАРУ")
                        .padding(.bottom, 7)
                    picker
                        .padding(.bottom, 18)
                    inputTextLabel("ВВЕДИТЕ ФИО ВЛАДЕЛЬЦА")
                        .padding(.bottom, 7)
                    textField
                        .padding(.bottom, 24)
                    certFieldRows
                }
                .sizeReader(size: $scrollContentSize)
                .padding(.top, 6)
                .padding(.bottom, 12)
            } onOffsetChanged: { offset in
                guard scrollContentSize.height != 0.0 else { return }
                let diff = wholeContentSize.height - scrollContentSize.height
                withAnimation(.easeInOut(duration: 0.3)) {
                    isTopViewShown = offset < -15
                    isBottomViewShown = offset > diff
                }
            }
            .sizeReader(size: $wholeContentSize)
            .gesture(DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
            )
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .scrollIndicators(.hidden)
            certViewBottom
        }
        .rtAdaptToKeyboard(onAppear: { if UIDevice.isPhone { bottomPadding = 12 }},
                           onDisappear: { if UIDevice.isPhone { bottomPadding = 34 }})
        .onChange(of: store.state.caGenerateCertState.inProgress) { newValue in
            inProgress = newValue
        }
    }

    private func inputTextLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(Color.RtColors.rtLabelSecondary)
            .padding(.leading, 12)
    }

    private var picker: some View {
        Picker("", selection: $selectedKey) {
            ForEach(0..<store.state.caGenerateCertState.keys.count, id: \.self) {
                Text(store.state.caGenerateCertState.keys[$0].ckaId)
            }
        }
        .frame(height: 44)
        .tint(Color.RtColors.rtColorsSecondary)
        .background(Color.RtColors.rtSurfaceQuaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var textField: some View {
        HStack {
            TextField("ФИО", text: $nameInput)
                .frame(height: 44)
                .textFieldStyle(PlainTextFieldStyle())
                .textContentType(.name)
                .padding(.horizontal, 12)
            if !nameInput.isEmpty {
                Button {
                    nameInput = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .tint(Color.RtColors.rtIosElementsInputClearSurface)
                }
                .padding(.trailing, 12)
            }
        }
        .background(Color.RtColors.rtSurfaceQuaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var certFieldRows: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(SubjectEntryTitle.allCases.dropFirst(), id: \.self) { field in
                VStack(alignment: .leading, spacing: 0) {
                    Text(field.fullName)
                        .font(.system(size: 17))
                        .foregroundStyle(Color.RtColors.rtLabelPrimary)
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                    Text(field.defaultValueForModel)
                        .font(.system(size: 17))
                        .foregroundStyle(Color.RtColors.rtLabelSecondary)
                        .padding(.bottom, 12)
                    if field != SubjectEntryTitle.allCases.last {
                        Divider()
                            .overlay(Color("otherSeparator"))
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .background(Color.RtColors.rtSurfaceQuaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var certViewHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Тестовый сертификат")
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.RtColors.rtLabelPrimary)
                    .padding(.vertical, 2.5)
                Spacer()
                Button {
                    store.send(.hideSheet)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(Color("iOSElementsCloseButtonIcon"),
                                         Color("iOSElementsCloseButtonSurface"))
                }
                .disabled(inProgress)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .padding(.top, 14)
            .background {
                Color("IOSElementsTitleBarSurface")
                    .background(.ultraThinMaterial)
                    .opacity(isTopViewShown ? 1 : 0)
            }
            Divider()
                .overlay(Color("IOSElementsTitleBarSeparator"))
                .opacity(isTopViewShown ? 1 : 0)
        }
    }

    private var certViewBottom: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color("IOSElementsTitleBarSeparator"))
                .opacity(isBottomViewShown ? 1 : 0)
            Button {
                if let token = store.state.connectedTokenState.connectedToken,
                   let pin = store.state.connectedTokenState.pin {
                    let id = store.state.caGenerateCertState.keys[selectedKey].ckaId
                    store.send(.generateCert(token.connectionType, token.serial, pin, id, nameInput))
                } else {
                    store.send(.showAlert(.unknownError))
                }
            } label: {
                buttonLabel
                    .frame(height: 50)
                    .frame(maxWidth: UIDevice.isPhone ? .infinity : 350)
            }
            .disabled(nameInput.isEmpty || inProgress || store.state.nfcState.isLocked)
            .background(nameInput.isEmpty || store.state.nfcState.isLocked
                        ? Color.RtColors.rtOtherDisabled
                        : Color.RtColors.rtColorsPrimary100
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, bottomPadding)
            .frame(maxWidth: .infinity)
            .background {
                Color("IOSElementsTitleBarSurface")
                    .background(.ultraThinMaterial)
                    .opacity(isBottomViewShown ? 1 : 0)
            }
        }
    }

    @ViewBuilder
    private var buttonLabel: some View {
        if inProgress {
            RtLoadingIndicator(.small)
                .padding(.vertical, 13)
        } else {
            Text("Сгенерировать")
                .font(.headline)
                .foregroundStyle(nameInput.isEmpty
                                 ? Color.RtColors.rtLabelTertiary
                                 : Color.RtColors.rtColorsOnPrimary
                )
                .padding(.vertical, 15)
        }
    }
}

struct CertGenView_Previews: PreviewProvider {
    static var previews: some View {
        let state = AppState(caGenerateCertState: CaGenerateCertState(
            keys: [KeyModel(ckaId: "12345678", type: .gostR3410_2012_256),
                   KeyModel(ckaId: "87654321", type: .gostR3410_2012_256)]))
        let store = Store(initialState: state,
                          reducer: AppReducer(),
                          middlewares: [])
        CaCertGenView()
            .frame(width: UIDevice.isPhone ? .infinity : 540,
                   height: UIDevice.isPhone ? 786 : 720)
            .background(Color.RtColors.rtSurfaceSecondary)
            .environmentObject(store)
    }
}
