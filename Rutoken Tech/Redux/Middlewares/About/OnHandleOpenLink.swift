//
//  OnHandleOpenLink.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 09.02.2024.
//

import UIKit

import TinyAsyncRedux


class OnHandleOpenLink: Middleware {
    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .openLink(linkType) = action else {
            return nil
        }

        guard let link = linkType.getUrl else { return nil }
        UIApplication.shared.open(link)
        return nil
    }
}
