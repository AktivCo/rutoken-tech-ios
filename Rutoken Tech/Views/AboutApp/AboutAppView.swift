//
//  AboutAppView.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 02.02.2024.
//

import SwiftUI

import RtUiComponents
import TinyAsyncRedux


struct AboutAppView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>

    private let phoneNumber = "+7 (495) 925-77-90"
    private let privacyPolicyURL = "rutoken.ru"
    private let appLicenseURL = "www.rutoken.ru/download/license/License_Agreement_Rutoken.pdf"

    func createLabel(_ text: String) -> some View {
        HStack(spacing: 0) {
            Text(text)
                .font(.body)
                .foregroundStyle(Color.RtColors.rtColorsSecondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
    }

    var logoView: some View {
        VStack(spacing: 0) {
            Image("AppLogo")
                .resizable()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .frame(width: 96, height: 96)
                .padding(.vertical, 12)
            Text("Рутокен Технологии")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.RtColors.rtLabelPrimary)
            Text("Компания «Актив»")
                .font(.body)
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
                .padding(.bottom, 12)
        }
        .frame(height: 180)
    }

    var infoList: some View {
        VStack(spacing: 0) {
            createLabel("Версия сборки", Bundle.main.fullVersion)
            Divider()
                .padding(.horizontal, 12)
            createLabel("Commit ID", Bundle.main.commitId)
        }
        .infoListStyle()
        .padding(.vertical, 12)
    }

    var linkList: some View {
        VStack(spacing: 0) {
            Button {
                store.send(.openLink(.browser(privacyPolicyURL)))
            } label: {
                createLabel("Политика конфиденциальности")
            }
            .buttonStyle(RtBackgroundAnimatedButtonStyle(pressedColor: .RtColors.rtOtherSelected))
            Divider()
                .padding(.horizontal, 12)
            Button {
                store.send(.openLink(.browser(appLicenseURL)))
            } label: {
                createLabel("Лицензионное соглашение Рутокен")
            }
            .buttonStyle(RtBackgroundAnimatedButtonStyle(pressedColor: .RtColors.rtOtherSelected))
        }
        .infoListStyle()
        .padding(.vertical, 12)
    }

    var contactsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ТЕХНИЧЕСКАЯ ПОДДЕРЖКА")
                .font(.footnote)
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
                .padding(.leading, 12)
                .padding(.top, 6)
                .padding(.bottom, 7)
            Button {
                store.send(.openLink(.phone(phoneNumber)))
            } label: {
                HStack(spacing: 0) {
                    Text("Телефон")
                        .font(.body)
                        .foregroundStyle(Color.RtColors.rtLabelPrimary)
                    Spacer()
                    Text(phoneNumber)
                        .font(.body)
                        .foregroundStyle(Color.RtColors.rtColorsSecondary)
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
            }
            .buttonStyle(RtBackgroundAnimatedButtonStyle(pressedColor: .RtColors.rtOtherSelected))
            .infoListStyle()
        }
        .frame(height: 85)
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderTitleView(title: "О приложении")
            logoView
            infoList
            linkList
            contactsView
            Spacer()
        }
        .frame(maxWidth: 642, alignment: .top)
        .padding(.top, 44)
        .padding(.horizontal, 20)
    }
}

struct AboutAppView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store(initialState: AppState(),
                          reducer: AppReducer(),
                          middlewares: [])
        ZStack {
            Color.RtColors.rtSurfaceSecondary
                .ignoresSafeArea()
            VStack(spacing: 0) {
                AboutAppView()
                    .environmentObject(store)
            }
        }
    }
}
