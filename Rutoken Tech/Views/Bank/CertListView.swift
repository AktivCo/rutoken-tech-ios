//
//  CertListView.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 19.02.2024.
//

import SwiftUI

import RtUiComponents
import TinyAsyncRedux


public struct CertListView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>

    @State var showTitle = false
    @State var headerSize: CGSize = .zero

    var certList: some View {
        VStack(spacing: 12) {
            ForEach(store.state.bankCertListState.certs, id: \.id) { cert in
                Button {
                    store.send(.selectCert(cert))
                } label: {
                    CertView(cert: cert)
                }
                .buttonStyle(RtBackgroundAnimatedButtonStyle(pressedColor: .RtColors.rtOtherSelected))
                .background { Color.RtColors.rtSurfaceQuaternary }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(cert.causeOfInvalid != nil)
            }
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer()
                Button("Отменить") {
                    store.send(.hideSheet)
                }
                .frame(height: 44)
                .foregroundColor(Color.RtColors.rtColorsSecondary)
            }
            .overlay {
                Text("Выберите сертификат")
                    .font(.headline)
                    .opacity(showTitle ? 1 : 0)
            }
            .padding(.top, 6)
            .padding(.bottom, 11)
            .padding(.trailing, 20)
            .background {
                Color("IOSElementsTitleBarSurface")
                    .background(.ultraThinMaterial)
                    .opacity(showTitle ? 1 : 0)
            }
            Divider()
                .overlay(Color("IOSElementsTitleBarSeparator"))
                .opacity(showTitle ? 1 : 0)
            ScrollViewOffset {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Выберите сертификат")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.RtColors.rtLabelPrimary)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 5)
                        .sizeReader(size: $headerSize)
                        .padding(.bottom, 12)
                    certList
                        .padding(.top, 12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 54)
            } onOffsetChanged: { offset in
                withAnimation(Animation.easeInOut(duration: 0.2)) {
                    showTitle = -offset > headerSize.height
                }
            }
            .padding(.horizontal, UIDevice.isPhone ? 20 : 76)
        }
    }
}

#if DEBUG
struct CertListView_Previews: PreviewProvider {
    static var previews: some View {
        let certListState = BankCertListState(certs: [
            .init(),
            .init(reason: .alreadyExist),
            .init(reason: .notStartedBefore(Date()))
        ])

        let state = AppState(bankCertListState: certListState)
        let testStore = Store(initialState: state,
                              reducer: AppReducer(),
                              middlewares: [])
        ZStack {
            Color.RtColors.rtSurfaceSecondary
                .ignoresSafeArea()
            CertListView()
                .environmentObject(testStore)
        }
    }
}
#endif
