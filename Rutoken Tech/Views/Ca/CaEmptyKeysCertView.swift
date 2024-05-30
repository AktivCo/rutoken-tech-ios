//
//  CaEmptyKeysCertView.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 26.01.2024.
//

import SwiftUI

import TinyAsyncRedux


struct CaEmptyKeysCertView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>
    var body: some View {
        ZStack(alignment: .top) {
            certViewHeader
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .padding(.top, 15)
            VStack {
                Spacer()
                Text("На Рутокене нет ни одной ключевой пары")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.RtColors.rtLabelSecondary)
                Spacer()
            }
        }
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
            }
        }
    }
}

struct CaEmptyKeysCertView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store(initialState: AppState(),
                               reducer: AppReducer(),
                               middlewares: [])
        CaEmptyKeysCertView()
            .frame(width: UIDevice.isPhone ? .infinity : 540,
                   height: UIDevice.isPhone ? 391 : 640)
            .background(Color.RtColors.rtSurfaceSecondary)
            .environmentObject(store)
            .previewDisplayName("No keys view")
    }
}
