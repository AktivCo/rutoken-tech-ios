//
//  CaGenerateKeyPairView.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 08.12.2023.
//

import SwiftUI

import RtUiComponents
import TinyAsyncRedux


struct CaGenerateKeyPairView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>

    func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.body)
                .padding(.bottom, 4)
                .foregroundStyle(Color.RtColors.rtLabelPrimary)
            Text(value)
                .font(.body)
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("Ключевая пара")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top, 2.5)
                Spacer()
                Button {
                    store.send(.hideSheet)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(
                            Color("iOSElementsCloseButtonIcon"),
                            Color("iOSElementsCloseButtonSurface")
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .padding(.top, 14)

            VStack(spacing: 0) {
                infoRow(label: "ID",
                        value: store.state.caGenerateKeyPairState.key?.ckaId ?? "")
                .padding(12)
                Divider()
                    .overlay(Color("otherSeparator"))
                    .padding(.horizontal, 12)
                infoRow(label: "Алгоритм",
                        value: store.state.caGenerateKeyPairState.key?.type.description ?? "")
                .padding(12)
            }
            .background(Color("surfacePrimary"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .topLeading)

            Spacer()
            Button {
                if let connectedToken = store.state.connectedTokenState.connectedToken,
                   let pin = store.state.connectedTokenState.pin,
                   let id = store.state.caGenerateKeyPairState.key?.ckaId {
                    store.send(.generateKeyPair(connectedToken.connectionType, connectedToken.serial, pin, id))
                } else {
                    store.send(.showAlert(.unknownError))
                }
            } label: {
                if store.state.caGenerateKeyPairState.inProgress {
                    RtLoadingIndicator(.small)
                        .padding(.vertical, 15)
                } else {
                    Text("Сгенерировать")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.headline)
                        .foregroundStyle(Color.RtColors.rtColorsOnPrimary)
                        .padding(.vertical, 15)
                }
            }
            .frame(maxWidth: UIDevice.isPhone ? .infinity : 350)
            .background { Color.RtColors.rtColorsPrimary100 }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .padding(.bottom, UIDevice.isPhone ? 34 : 24)
        }
    }
}

struct CaGenKeyPairView_Previews: PreviewProvider {
    static var previews: some View {

        let state = AppState(caGenerateKeyPairState: CaGenerateKeyPairState(
            key: KeyModel(ckaId: "12345678-90abcdef",
                          type: .gostR3410_2012_256)))

        let testStore = Store(initialState: state,
                              reducer: AppReducer(),
                              middlewares: [])

        CaGenerateKeyPairView()
            .environmentObject(testStore)
            .background(Color.RtColors.rtSurfaceSecondary)
    }
}
