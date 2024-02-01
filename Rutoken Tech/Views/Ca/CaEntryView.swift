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
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                .foregroundStyle(Color.RtColors.rtLabelPrimary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
        }
        .frame(height: 44)
        .padding(.horizontal, 12)
    }

    func actionRow(_ label: String, callback: @escaping () -> Void) -> some View {
        Button {
            callback()
        } label: {
            HStack(spacing: 0) {
                Text(label)
                    .font(.body)
                    .foregroundStyle(Color.RtColors.rtLabelPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("otherChevron"))
            }
            .frame(height: 44)
            .padding(.horizontal, 12)
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
                actionRow("Сгенерировать ключевую пару") {
                    store.send(.generateKeyId)
                    store.send(.showSheet(true, UIDevice.isPhone ? .smallPhone : .ipad(width: 540, height: 640), {
                        CaGenerateKeyPairView().environmentObject(store)
                    }()))
                }
                Divider()
                    .padding(.horizontal, 12)
                actionRow("Выпустить тестовый сертификат") {
                    if store.state.caGenerateCertState.keys.isEmpty {
                        store.send(.showSheet(true, UIDevice.isPhone ? .smallPhone : .ipad(width: 540, height: 640), {
                            CaEmptyKeysCertView()
                                .environmentObject(store)
                        }()))
                    } else {
                        store.send(.showSheet(true, UIDevice.isPhone ? .largePhone : .ipad(width: 540, height: 720), {
                            CaCertGenView()
                                .environmentObject(store)
                        }()))
                    }
                }
            }
            .listStyle()
        }
    }

    func connectedTokenView(_ connectedToken: TokenInfo) -> some View {
        ScrollView {
            VStack(alignment: .center) {
                switch connectedToken.type {
                case .dual: Image("token-usb-nfc")
                case .sc: Image("token-nfc")
                case .usb: Image("token-usbc")
                }
            }
            .frame(width: 137, height: 88)
            .padding(.vertical, 32)

            infoList(for: connectedToken)
        }
        .scrollDisabled(true)
    }

    func disconnectedTokenView() -> some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Подключите Рутокен")
                .foregroundStyle(Color.RtColors.rtLabelPrimary)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 4)

            Text("Чтобы воспользоваться\n«Удостоверяющим центром»")
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .padding(.bottom, 8)

            Button {
                store.send(.showSheet(false, UIDevice.isPhone ? .largePhone : .ipad(width: 540, height: 640), {
                    RtAuthView(defaultPinGetter: { "12345678" },
                               onSubmit: { tokenType, pin in store.send(.selectToken(tokenType, pin)) },
                               onCancel: { store.send(.hideSheet) })
                    .environmentObject(store.state.routingState.pinInputError)
                }()))
            } label: {
                Text("Подключить")
                    .tint(Color.RtColors.rtColorsSecondary)
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
                if store.state.connectedTokenState.connectedToken != nil {
                    Button(action: {
                        store.send(.logoutCa)
                    }, label: {
                        Text("Выйти")
                            .padding(.leading, 20)
                    })
                    .foregroundStyle(Color.RtColors.rtColorsSecondary)
                    Spacer()
                }
            }
            .frame(height: 44)

            VStack(spacing: 0) {
                Text("Удостоверяющий центр")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.RtColors.rtLabelPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 5)
                    .padding(.bottom, 12)
                if let connectedToken = store.state.connectedTokenState.connectedToken {
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
            Color.RtColors.rtSurfaceSecondary
                .ignoresSafeArea()
            CaEntryView()
                .environmentObject(store)
        }

        let token = TokenInfo(label: "Ivan",
                              serial: "274-10-01",
                              model: .rutoken3Nfc,
                              connectionType: .nfc,
                              type: .sc)
        let state = AppState(connectedTokenState: ConnectedTokenState(connectedToken: token))
        let testStore = Store(initialState: state,
                              reducer: AppReducer(),
                              middlewares: [])
        ZStack {
            Color.RtColors.rtSurfaceSecondary
                .ignoresSafeArea()
            CaEntryView()
                .environmentObject(testStore)
        }
    }
}

