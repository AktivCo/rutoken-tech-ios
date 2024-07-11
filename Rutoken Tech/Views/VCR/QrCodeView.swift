//
//  QrCodeView.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 08.07.2024.
//

import SwiftUI

import TinyAsyncRedux


struct QrCodeView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>
    @State private var currentBrightness = UIScreen.main.brightness

    let qrCodeImage: Image

    var body: some View {
        VStack {
            topView
                .frame(height: 44)
                .padding(.top, 6)
            switch store.state.vcrState.qrCodeTimer {
            case .expired:
                qrCodeExpired
            case let .countdown(seconds, percentage):
                timerView(seconds: seconds, percentage: percentage)
            }
        }
        .background(Color("surfacePrimary"))
        .onAppear {
            currentBrightness = UIScreen.main.brightness
            ScreenBrightnessController.shared.setBrightness(to: 1)
        }
        .onDisappear {
            ScreenBrightnessController.shared.setBrightness(to: currentBrightness)
        }
    }

    private var qrCodeExpired: some View {
        VStack {
            Spacer()
            Text("Срок действия QR-кода истек")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.RtColors.rtLabelPrimary)
                .padding(.bottom, 4)
            Text("Нажмите на кнопку “Сгенерировать” для повторной генерации QR-кода")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            Button {
                store.send(.generateQrCode)
            } label: {
                Text("Сгенерировать")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.RtColors.rtColorsSecondary)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 7)
            }
            Spacer()
        }
    }

    private var topView: some View {
        CustomNavBar {
            Button {
                store.send(.invalidateQrCodeTimer)
                store.send(.updateQrCode(nil))
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.backward")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 19)
                    Text("Виртуальный считыватель")
                        .font(.system(size: 17))
                }
                .foregroundStyle(Color.RtColors.rtColorsSecondary)
            }
            .padding(.leading, 11)
        } center: {
            Text("QR-код")
                .font(.headline)
        } right: {
            Button {
                store.send(.invalidateQrCodeTimer)
                store.send(.hideSheet)
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    store.send(.updateQrCode(nil))
                }
            } label: {
                Text("Закрыть")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.RtColors.rtColorsSecondary)
            }
            .padding(.trailing, 20)
        }

    }

    private func timerView(seconds: Int, percentage: Double) -> some View {
        VStack {
            Spacer()
            Text("Отсканируйте QR-код в приложении  Рутокен VCR")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
                .padding(.bottom, 24)
            qrCodeImage
                .resizable()
                .padding(4)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("otherSeparator"), lineWidth: 0.5)
                )
                .frame(width: 384, height: 384)
                .padding(.bottom, 24)
            ZStack {
                Circle()
                    .stroke(
                        Color.RtColors.rtSurfaceSecondary,
                        lineWidth: 4
                    )
                Circle()
                    .trim(from: 0, to: 1 - percentage)
                    .stroke(
                        Color.RtColors.rtColorsSecondary,
                        style: StrokeStyle(
                            lineWidth: 4,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                Text("\(seconds)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.RtColors.rtLabelPrimary)
            }
            .frame(width: 64, height: 64)
            Spacer()
        }
    }
}

struct QrCodeView_Previews: PreviewProvider {
    static var previews: some View {
        let qrActiveState = AppState(vcrState: VcrState(qrCodeTimer: .countdown(90, 0.25)))
        let qrActiveStore = Store(initialState: qrActiveState, reducer: AppReducer(), middlewares: [])
        let store = Store(initialState: AppState(), reducer: AppReducer(), middlewares: [])
        ZStack {
            Color.RtColors.rtOtherDisabled
                .ignoresSafeArea(.all)
            QrCodeView(qrCodeImage: Image(systemName: "qrcode"))
                .previewDevice("iPad (10th generation)")
                .frame(width: 624, height: 720)
                .environmentObject(qrActiveStore)
        }
        ZStack {
            Color.RtColors.rtOtherDisabled
                .ignoresSafeArea(.all)
            QrCodeView(qrCodeImage: Image(systemName: "qrcode"))
                .previewDevice("iPad (10th generation)")
                .frame(width: 624, height: 720)
                .environmentObject(qrActiveStore)
        }
        .preferredColorScheme(.dark)
        ZStack {
            Color.RtColors.rtOtherDisabled
                .ignoresSafeArea(.all)
            QrCodeView(qrCodeImage: Image(systemName: "qrcode"))
                .previewDevice("iPad (10th generation)")
                .frame(width: 624, height: 720)
                .environmentObject(store)
        }
        ZStack {
            Color.RtColors.rtOtherDisabled
                .ignoresSafeArea(.all)
            QrCodeView(qrCodeImage: Image(systemName: "qrcode"))
                .previewDevice("iPad (10th generation)")
                .frame(width: 624, height: 720)
                .environmentObject(store)
        }
        .preferredColorScheme(.dark)
    }
}
