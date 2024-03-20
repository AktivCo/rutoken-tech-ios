//
//  ProcessInfo+isPreview.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.03.2024.
//

import Foundation


extension ProcessInfo {
    static var isPreview: Bool {
        Self.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
