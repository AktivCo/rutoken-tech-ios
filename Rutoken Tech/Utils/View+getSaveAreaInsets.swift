//
//  View+getSaveAreaInsets.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 19.04.2024.
//

import SwiftUI


func getSafeAreaInsets() -> UIEdgeInsets? {
    let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    return scene?.keyWindow?.safeAreaInsets
}
