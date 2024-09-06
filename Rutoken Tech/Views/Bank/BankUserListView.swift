//
//  BankUserListView.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 14.02.2024.
//

import SwiftUI

import RtUiComponents
import TinyAsyncRedux


struct BankUserListView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>

    let maxUserCount = 3

    var body: some View {
        Group {
            if UIDevice.isPhone {
                iphoneView
            } else {
                ipadView
            }
        }
        .onAppear {
            store.state.bankSelectUserState.userListModel.onSelectCallback = { user in
                guard user.expiryDate > Date() else {
                    return
                }

                store.send(.showSheet(false, UIDevice.isPhone ? .largePhone : .ipad(width: 540, height: 640), {
                    RtAuthView(defaultPinGetter: {
                        store.send(.updatePin(RutokenTechApp.defaultPin))
                    }, onSubmit: { tokenType, pin in
                        store.send(.authUser(tokenType, pin, user))
                    }, onCancel: {
                        store.send(.hideSheet)
                        store.send(.updatePin(""))
                    })
                    .environmentObject(store.state.routingState.pinInputModel)
                }()))
            }
            store.state.bankSelectUserState.userListModel.onDeleteCallback = { user in
                store.send(.deleteUser(user))
            }
        }
    }

    private var iphoneView: some View {
        NavigationStack {
            ZStack {
                Color.RtColors.rtSurfaceSecondary
                    .ignoresSafeArea()
                mainView
                    .navigationDestination(isPresented: Binding(
                        get: { store.state.bankSelectUserState.selectedUser != nil },
                        set: { ok in if !ok { store.send(.selectUser(nil)) } })) {
                            PaymentListView()
                                .navigationBarBackButtonHidden(true)
                                .ignoresSafeArea(.container, edges: [.top])
                        }
            }
        }
    }

    // due to incorrect interaction between NavigationStack inside of NavigationSplitView
    // we add two different view declarations
    private var ipadView: some View {
        ZStack {
            Color.RtColors.rtSurfaceSecondary
                .ignoresSafeArea()
            if store.state.bankSelectUserState.selectedUser != nil {
                PaymentListView()
                    .ignoresSafeArea(.container, edges: [.top])
            } else {
                mainView
            }
        }
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            HeaderTitleView(title: "Пользователи")
            if store.state.bankSelectUserState.userListModel.items.isEmpty {
                noUsersView
            } else {
                RtList(listModel: store.state.bankSelectUserState.userListModel)
                    .padding(.top, 12)
            }
            bottomView
        }
        .padding(.top, 44)
        .padding(.horizontal, 20)
    }

    private var noUsersView: some View {
        VStack {
            Spacer()
            Text("Нет добавленных пользователей")
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
        }
    }

    private var bottomView: some View {
        VStack {
            if store.state.bankSelectUserState.userListModel.items.count < maxUserCount {
                Spacer()
                Button {
                    store.send(.showSheet(false, UIDevice.isPhone ? .largePhone : .ipad(width: 540, height: 640), {
                        RtAuthView(defaultPinGetter: { store.send(.updatePin(RutokenTechApp.defaultPin)) },
                                   onSubmit: { tokenType, pin in store.send(.readCerts(tokenType, pin)) },
                                   onCancel: { store.send(.hideSheet) })
                        .environmentObject(store.state.routingState.pinInputModel)
                    }()))
                } label: {
                    Text("Добавить пользователя")
                }
                .buttonStyle(RtRoundedFilledButtonStyle(isPressable: true))
                .frame(maxWidth: UIDevice.isPhone ? .infinity : 350)
                .padding(.bottom, 20)
            } else {
                Text("Вы добавили максимальное количество пользователей. Чтобы добавить нового, удалите одного из существующих")
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
                .font(.system(size: 13))
                .padding(.top, 12)
                Spacer()
            }
        }
    }
}

struct UserSelectView_Previews: PreviewProvider {
    static var previews: some View {
        let user1 = BankUserInfo(
            expiryDate: Date().addingTimeInterval(5), fullname: "Иванов Михаил Романович",
            title: "Дизайнер", keyId: "", certHash: "", tokenSerial: "")

        let user2 = BankUserInfo(
            expiryDate: Date().addingTimeInterval(300), fullname: "Иванов Валерий Романович",
            title: "Дизайнер", keyId: "", certHash: "", tokenSerial: "")

        let user3 = BankUserInfo(
            expiryDate: Date().addingTimeInterval(-20), fullname: "Иванов Никита Романович",
            title: "Дизайнер", keyId: "", certHash: "", tokenSerial: "")

        let state = AppState(bankSelectUserState: BankSelectUsersState())
        let store = Store(initialState: state,
                          reducer: AppReducer(),
                          middlewares: [])
        ZStack {
            Color.RtColors.rtSurfaceSecondary
                .ignoresSafeArea()
            BankUserListView()
                .environmentObject(store)
                .onAppear {
                    store.state.bankSelectUserState.userListModel.items = [user1, user2, user3]
                }
        }
    }
}
