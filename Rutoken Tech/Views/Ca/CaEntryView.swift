//
//  CaEntryView.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 08.11.2023.
//

import SwiftUI

import TinyAsyncRedux

import RtUiComponents


private struct ListStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color("surfacePrimary"))
            .cornerRadius(12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private extension View {
    func listStyle() -> some View {
        modifier(
            ListStyle()
        )
    }
}

struct CaEntryView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>

    func infoRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.body)
                .foregroundStyle(Color("labelPrimary"))
            Spacer()
            Text(value)
                .font(.body)
                .foregroundStyle(Color("labelSecondary"))
        }
        .frame(height: 44)
        .padding(.horizontal, 12)
    }

    func activeRow(_ label: String, callback: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.body)
                .foregroundStyle(Color("labelPrimary"))
            Spacer()
            Image(systemName: "chevron.right")
                .fontWeight(.semibold)
                .foregroundStyle(Color("otherChevron"))
        }
        .frame(height: 44)
        .padding(.horizontal, 12)
        .onTapGesture {
            callback()
        }
    }

    func infoList(for token: TokenInfo) -> some View {
        Group {
            VStack(spacing: 0) {
                infoRow("Метка", token.label)
                Divider()
                    .padding(.horizontal, 12)
                infoRow("Модель", token.model.rawValue)
                Divider()
                    .padding(.horizontal, 12)
                infoRow("Серийный номер", token.serial)
            }
            .listStyle()

            VStack(spacing: 0) {
                activeRow("Сгенерировать ключевую пару") {
                }
                Divider()
                    .padding(.horizontal, 12)
                activeRow("Выпустить тестовый сертификат") {
                }
            }
            .listStyle()
        }
    }

    func connectedTokenView(_ connectedToken: TokenInfo) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .center) {
                if connectedToken.type == .dual {
                    Image("token-usb-nfc")
                } else if connectedToken.type == .sc {
                    Image("token-nfc")
                } else if connectedToken.type == .usb {
                    Image("token-usbc")
                }
            }
            .frame(width: 137, height: 88)
            .padding(.vertical, 32)

            infoList(for: connectedToken)
            Spacer()
        }
    }

    func disconnectedTokenView() -> some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Подключите Рутокен")
                .foregroundStyle(Color("labelPrimary"))
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 4)

            Text("Чтобы воспользоваться\n«Удостоверяющим центром»")
                .foregroundStyle(Color("labelSecondary"))
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .padding(.bottom, 8)

            Button {
                store.send(.showSheet(
                    .init(isDraggable: false,
                          size: UIDevice.isPhone ? .largePhone : .ipad(width: 540, height: 640),
                          content: AnyView(
                            RtAuthView(defaultPinGetter: { "12345678" },
                                       onSubmit: { tokenType, pin in store.send(.selectToken(tokenType, pin)) },
                                       onCancel: { store.send(.hideSheet) })
                            .environmentObject(store.state.routingState.pinInputError)))))
            } label: {
                Text("Подключить")
                    .tint(Color("colorsSecondary"))
                    .font(.subheadline)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 7)
            }
            .frame(height: 34)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if store.state.caEntryViewState.connectedToken != nil {
                    Button(action: {
                    }, label: {
                        Text("Выйти")
                            .padding(.leading, 20)
                    })
                    .foregroundStyle(Color("colorsSecondary"))
                    Spacer()
                }
            }
            .frame(height: 44)

            VStack(spacing: 0) {
                Text("Удостоверяющий центр")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("labelPrimary"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 5)
                    .padding(.bottom, 12)
                if let connectedToken = store.state.caEntryViewState.connectedToken {
                    connectedTokenView(connectedToken)
                } else {
                    disconnectedTokenView()
                }
            }
            .frame(maxWidth: 642, alignment: .top)
            .padding(.horizontal, 20)
        }
    }
}

struct CaEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store(initialState: AppState(),
                          reducer: AppReducer(),
                          middlewares: [])
        ZStack {
            Color("surfaceSecondary")
                .ignoresSafeArea()
            VStack(spacing: 0) {
                CaEntryView()
                    .environmentObject(store)
            }
        }

        let token = TokenInfo(label: "Ivan",
                              serial: "274-10-01",
                              model: .rutoken3Nfc,
                              connectionType: .nfc,
                              type: .sc)
        let state = AppState(caEntryViewState: CaEntryViewState(connectedToken: token))
        let testStore = Store(initialState: state,
                              reducer: AppReducer(),
                              middlewares: [])
        ZStack {
            Color("surfaceSecondary")
                .ignoresSafeArea()
            VStack(spacing: 0) {
                CaEntryView()
                    .environmentObject(testStore)
            }
        }
    }
}

