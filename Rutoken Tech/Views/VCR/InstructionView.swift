//
//  InstructionView.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 08.07.2024.
//

import SwiftUI

import RtUiComponents
import TinyAsyncRedux


struct VcrView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>

    var body: some View {
        if store.state.vcrState.qrCode != nil {
        } else {
            InstructionView()
        }
    }
}

struct InstructionView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>
    @State private var isBottomViewShown = true
    @State private var isTopViewShown = false
    @State private var isTitleShown = false
    @State private var visibleContentSize: CGSize = .zero
    @State private var wholeContentSize: CGSize = .zero
    @State private var imageAndTitleSize: CGSize = .zero
    private let topViewPadding: CGFloat = 24

    var body: some View {
        ZStack {
            VStack {
                topView
                    .background(Color("surfacePrimary").opacity(0.75))
                    .background(.ultraThinMaterial.opacity(isTopViewShown ? 1 : 0))
                Spacer()
            }
            .zIndex(10)
            ScrollViewOffset {
                mainView
                    .padding(.top, 56)
                    .padding(.bottom, 126)
                    .rtSizeReader(size: $wholeContentSize)
                    .padding(.bottom, 36)
            } onOffsetChanged: { offset in
                guard wholeContentSize.height != 0.0 else { return }
                let diff = visibleContentSize.height - wholeContentSize.height
                withAnimation(.easeInOut(duration: 0.3)) {
                    isTitleShown = offset < -(imageAndTitleSize.height + topViewPadding)
                    isTopViewShown = offset < -topViewPadding
                    isBottomViewShown = offset > diff
                }
            }
            .rtSizeReader(size: $visibleContentSize)
            VStack {
                Spacer()
                bottomView
                    .background(Color("surfacePrimary").opacity(0.75))
                    .background(.ultraThinMaterial.opacity(isBottomViewShown ? 1 : 0))
            }
            .zIndex(10)
        }
        .background(Color("surfacePrimary"))
    }

    private var topView: some View {
        VStack(spacing: 0) {
            CustomNavBar {
                EmptyView()
            } center: {
                Text("Виртуальный считыватель")
                    .font(.system(size: 17))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.RtColors.rtLabelPrimary)
                    .opacity(isTitleShown ? 1 : 0)
            } right: {
                Button {
                    store.send(.hideSheet)
                } label: {
                    Text("Закрыть")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.RtColors.rtColorsSecondary)
                }
                .padding(.trailing, 20)
            }
            .frame(height: 56)
            Divider()
                .overlay(Color("IOSElementsTitleBarSeparator"))
                .opacity(isTopViewShown ? 1 : 0)
        }
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            instructionsTopView
                .padding(.top, topViewPadding)
                .padding(.bottom, 32)
            instructionsListView
                .padding(.horizontal, 15)
                .frame(width: 368)
        }
    }

    private var instructionsTopView: some View {
        VStack(spacing: 0) {
            VStack(spacing: topViewPadding) {
                Image("VcrLogo")
                    .resizable()
                    .frame(width: 96, height: 96)
                Text("Виртуальный считыватель")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.RtColors.rtLabelPrimary)
            }
            .rtSizeReader(size: $imageAndTitleSize)
            .padding(.bottom, 12)

            VStack(spacing: 12) {
                Text("На iPad нет NFC-модуля, поэтому к нему нужно подключить виртуальный считыватель для устройств с NFC-интерфейсом.")
                Text("Таким считывателем может стать iPhone  с помощью приложения Рутокен VCR.")
            }
            .multilineTextAlignment(.center)
            .padding(.bottom, 24)

            VStack(spacing: 4) {
                Text("Как это работает")
                    .font(.system(size: 15, weight: .semibold))
                // swiftlint:disable:next line_length
                Text("Рутокен с NFC прикладывается к iPhone,  в котором есть NFC-модуль. А через приложение Рутокен VCR данные с Рутокена передаются на iPad.")
                    .font(.system(size: 13))
            }
            .multilineTextAlignment(.center)
            .padding(.vertical, 12)
            .frame(width: 368)
            .background(Color.iOSElementsSegmentedControlBG)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var instructionsListView: some View {
        VStack(alignment: .leading, spacing: 32) {
            instructionStepView(
                number: 1,
                title: "Установка",
                text: Text("Найдите приложение “Рутокен VCR” в AppStore и установите его на iPhone."))
            instructionStepView(
                number: 2,
                title: "Настройка",
                // swiftlint:disable:next no_more_than_one_consecutive_space line_length
                text: Text("Откройте приложение, задайте имя устройства, на главном экране нажмите \(Image(systemName: "plus.circle.fill")) для сканирования QR-кода."))
            instructionStepView(
                number: 3,
                title: "Добавление",
                text: Text("Нажмите “Добавить” для генерации QR-кода и отсканируйте его с помощью Рутокен VCR"))
        }
    }

    private func instructionStepView(number: Int, title: String, text: Text) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.RtColors.rtColorsOnPrimary)
                .background(Circle()
                    .fill(Color.RtColors.rtColorsSecondary)
                    .frame(width: 36, height: 36))
                .frame(width: 36, height: 36)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.RtColors.rtLabelPrimary)
                text
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.RtColors.rtLabelSecondary)
            }
        }
    }

    private var bottomView: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color("IOSElementsTitleBarSeparator"))
                .opacity(isBottomViewShown ? 1 : 0)
                .padding(.bottom, 12)
            Button {
                store.send(.generateQrCode)
            } label: {
                Text("Добавить")
            }
            .buttonStyle(RtRoundedFilledButtonStyle(isPressable: true))
            .frame(width: 350)
            .padding(.bottom, 4)
            Button {
                store.send(.hideSheet)
            } label: {
                Text("Настроить позже")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.RtColors.rtColorsSecondary)
                    .frame(width: 350, height: 50)
            }
            .padding(.bottom, 8)
        }
    }
}

struct InstructionView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store(initialState: AppState(), reducer: AppReducer(), middlewares: [])
        ZStack {
            Color.RtColors.rtOtherDisabled
                .ignoresSafeArea(.all)
            InstructionView()
                .frame(width: 624, height: 720)
                .environmentObject(store)
                .previewDevice("iPad (10th generation)")
        }
        ZStack {
            Color.RtColors.rtOtherDisabled
                .ignoresSafeArea(.all)
            InstructionView()
                .frame(width: 624, height: 720)
                .environmentObject(store)
                .previewDevice("iPad (10th generation)")
        }
        .preferredColorScheme(.dark)
    }
}
