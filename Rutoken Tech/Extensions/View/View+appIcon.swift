//
//  View+appIcon.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 05.02.2024.
//

import SwiftUI


extension View {
    var appIcon: UIImage! {
        guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
              let lastIcon = iconFiles.last else { return nil }
        return UIImage(named: lastIcon)
    }
}
