//
//  BankUserListView.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 14.02.2024.
//

import CoreData
import SwiftUI
import UIKit

import RtUiComponents
import TinyAsyncRedux


struct BankUserListView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>

    let maxUserCount = 3

    var body: some View {
        NavigationStack {
            ZStack {
                Color.RtColors.rtSurfaceSecondary
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    HeaderTitleView(title: "Пользователи")
                    if store.state.bankSelectUserState.users.isEmpty {
                        noUsersView
                    } else {
                        usersListView
                    }
                    bottomView
                }
                .padding(.top, 44)
                .padding(.horizontal, 20)
            }
        }
    }

    private var noUsersView: some View {
        VStack {
            Spacer()
            Text("Нет добавленных пользователей")
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
        }
    }

    private var usersListView: some View {
        VStack(spacing: 12) {
            ForEach(store.state.bankSelectUserState.users.prefix(maxUserCount), id: \.id) { user in
                UserListItem(name: user.fullname, title: user.title, expiryDate: user.expiryDate,
                             onDeleteUser: { store.send(.deleteUser(user)) },
                             onSelectUser: {
                    store.send(.showSheet(false, UIDevice.isPhone ? .largePhone : .ipad(width: 540, height: 640), {
                        RtAuthView(defaultPinGetter: {
                            store.send(.updatePin("12345678"))
                        }, onSubmit: { tokenType, pin in
                            store.send(.authUser(tokenType, pin, user))
                        }, onCancel: {
                            store.send(.hideSheet)
                            store.send(.updatePin(""))
                        })
                        .environmentObject(store.state.routingState.pinInputModel)
                    }()))
                })
                .navigationDestination(isPresented: Binding(
                    get: { store.state.bankSelectUserState.selectedUser != nil },
                    set: { _ in store.send(.selectUser(nil)) })) {
                        EmptyView()
                    }
            }
        }
        .padding(.top, 12)
    }

    private var bottomView: some View {
        VStack {
            if store.state.bankSelectUserState.users.count < maxUserCount {
                Spacer()
                Button {
                    store.send(.showSheet(false, UIDevice.isPhone ? .largePhone : .ipad(width: 540, height: 640), {
                        RtAuthView(defaultPinGetter: { store.send(.updatePin("12345678")) },
                                   onSubmit: { tokenType, pin in store.send(.readCerts(tokenType, pin)) },
                                   onCancel: { store.send(.hideSheet) })
                        .environmentObject(store.state.routingState.pinInputModel)
                    }()))
                } label: {
                    Text("Добавить пользователя")
                }
                .buttonStyle(RtRoundedFilledButtonStyle())
                .frame(maxWidth: UIDevice.isPhone ? .infinity : 350)
                .padding(.bottom, 20)
            } else {
                Text("Вы добавили максимальное количество пользователей. Чтобы добавить нового, удалите одного из существующих")
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
        let userManager = UserManager(inMemory: true)
        let user1 = try? userManager.createUser(
            fullname: "Иванов Михаил Романович",
            title: "Дизайнер",
            expiryDate: Date(), certId: "", tokenSerial: "")

        let user2 = try? userManager.createUser(
            fullname: "Иванов Михаил Романович",
            title: "Дизайнер",
            expiryDate: Date(), certId: "", tokenSerial: "")

        let user3 = try? userManager.createUser(
            fullname: "Иванов Михаил Романович",
            title: "Дизайнер",
            expiryDate: Date(), certId: "", tokenSerial: "")

        let state = AppState(bankSelectUserState: BankSelectUsersState(users: [user1!, user2!, user3!]))
        let store = Store(initialState: state,
                          reducer: AppReducer(),
                          middlewares: [])
        ZStack {
            Color.RtColors.rtSurfaceSecondary
                .ignoresSafeArea()
            BankUserListView()
                .environmentObject(store)
                .environment(\.managedObjectContext, userManager.context)
        }
    }
}
