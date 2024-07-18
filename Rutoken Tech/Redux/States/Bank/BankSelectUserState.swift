//
//  BankSelectUserState.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 19.02.2024.
//

import RtUiComponents


struct BankSelectUsersState {
    let userListModel = RtListModel<BankUserInfo, UserListItem>(items: [],
                                                                contentBuilder: { user, startToClose, isPressed in
        UserListItem(user: user, startToClose: startToClose, isPressed: isPressed)
    },
                                                                onSelect: { _ in},
                                                                onDelete: { _ in})
    var selectedUser: BankUserInfo?
}
