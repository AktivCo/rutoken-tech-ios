//
//  BankSelectUserView.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 14.02.2024.
//

import SwiftUI

import RtUiComponents
import TinyAsyncRedux


struct BankSelectUserView: View {
    @EnvironmentObject private var store: Store<AppState, AppAction>
    var body: some View {
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

    private var noUsersView: some View {
        VStack {
            Spacer()
            Text("Нет добавленных пользователей")
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
        }
    }

    private var usersListView: some View {
        VStack(spacing: 12) {
            ForEach(store.state.bankSelectUserState.users, id: \.id) { user in
                UserListItem(user: user, onRemoveUser: {
                    store.send(.removeUser(user))
                }, onSelectUser: { store.send(.selectUser(user))})
            }
        }
        .padding(.top, 12)
    }

    private var bottomView: some View {
        VStack {
            if store.state.bankSelectUserState.users.count < 3 {
                Spacer()
                Button {
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
        let user1 = BankUser(fullname: "Иванов Михаил Романович",
                             title: "Дизайнер",
                             expiryDate: "07.03.2024")

        let user2 = BankUser(fullname: "Иванов Роман Михайлович",
                             title: "Дизайнер",
                             expiryDate: "07.03.2024")

        let user3 = BankUser(fullname: "Романов Иван Михайлович",
                             title: "Дизайнер",
                             expiryDate: "07.03.2024")
        let state = AppState(bankSelectUserState: BankSelectUsersState(users: [user1, user2, user3]))
        let store = Store(initialState: state,
                          reducer: AppReducer(),
                          middlewares: [])
        ZStack {
            Color.RtColors.rtSurfaceSecondary
                .ignoresSafeArea()
            BankSelectUserView()
                .environmentObject(store)
        }
    }
}
