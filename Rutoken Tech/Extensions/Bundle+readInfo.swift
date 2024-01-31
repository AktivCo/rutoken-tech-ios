//
//  Bundle+readInfo.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 31.01.2024.
//

import Foundation


extension Bundle {
    private var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    private var buildNumber: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }

    var fullVersion: String {
        "\(appVersion)(\(buildNumber))"
    }

    var commitId: String {
        infoDictionary?["GitCommitHash"] as? String ?? "Unknown"
    }
}
