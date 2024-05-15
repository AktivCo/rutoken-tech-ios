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
    @State private var wholeContentSize: CGSize = .zero
    @State private var scrollContentSize: CGSize = .zero

    @State private var buttonState: RtContinueButtonState = .disabled

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
                .disabled(store.state.routingState.actionWithTokenButtonState == .inProgress)
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
            RtLoadingButton(
                action: {
                    if let token = store.state.caConnectedTokenState.connectedToken,
                       let pin = store.state.caConnectedTokenState.pin {
                        let id = store.state.caGenerateCertState.keys[selectedKey].ckaId
                        store.send(.generateCert(token.connectionType, serial: token.serial, pin: pin, id: id, commonName: nameInput))
                    } else {
                        store.send(.showAlert(.unknownError))
                    }
                },
                title: "Сгенерировать",
                state: buttonState)
            .frame(maxWidth: UIDevice.isPhone ? .infinity : 350)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, bottomPadding)
            .onAppear {
                buttonState = calculateButtonState()
            }
            .onChange(of: store.state.routingState.actionWithTokenButtonState) { _ in
                buttonState = calculateButtonState()
            }
            .onChange(of: nameInput) { _ in
                buttonState = calculateButtonState()
            }
        }
    }

    private func calculateButtonState() -> RtContinueButtonState {
        switch (store.state.routingState.actionWithTokenButtonState,
                store.state.caConnectedTokenState.connectedToken?.connectionType) {
        case (.ready, _):
            return nameInput.isEmpty ? .disabled : .ready
        case (.cooldown, .usb):
            return .ready
        default:
            return store.state.routingState.actionWithTokenButtonState
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
