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
    @State private var inProgress: Bool = false

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
                .disabled(inProgress)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .padding(.top, 14)

            VStack(spacing: 0) {
                infoRow(label: "ID",
                        value: store.state.caGenerateKeyPairState.key?.ckaId ?? "")
                .padding(12)
                // Cant use Divider() here, because it changes below infoRow background color
                // when scrolling down sheet with this view
                Rectangle()
                    .fill(Color("otherSeparator"))
                    .frame(height: 0.33)
                    .padding(.horizontal, 12)
                infoRow(label: "Алгоритм",
                        value: store.state.caGenerateKeyPairState.key?.type.description ?? "")
                .padding(12)
            }
            .background(Color.RtColors.rtSurfaceQuaternary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .topLeading)

            Spacer()
            RtLoadingButton(action: {
                if let connectedToken = store.state.caConnectedTokenState.connectedToken,
                   let pin = store.state.caConnectedTokenState.pin,
                   let id = store.state.caGenerateKeyPairState.key?.ckaId {
                    store.send(.generateKeyPair(connectedToken.connectionType, serial: connectedToken.serial, pin: pin, id: id))
                } else {
                    store.send(.showAlert(.unknownError))
                }
            }, title: "Сгенерировать",
                     inProgress: $inProgress)
            .disabled(store.state.nfcState.isLocked)
            .frame(maxWidth: UIDevice.isPhone ? .infinity : 350)
            .padding(.horizontal, 20)
            .padding(.bottom, UIDevice.isPhone ? 34 : 24)
        }
        .onChange(of: store.state.caGenerateKeyPairState.inProgress) { newValue in
            inProgress = newValue
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
            .background(.ultraThinMaterial)
            .background(Color.RtColors.rtSurfaceTertiary)
    }
}
