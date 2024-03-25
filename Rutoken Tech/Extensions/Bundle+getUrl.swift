//
//  Bundle+getUrl.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 25.03.2024.
//

import Foundation


extension Bundle {
    static func getUrl(for file: String, in subdir: String? = nil) -> URL? {
        Bundle.main.url(forResource: file,
                        withExtension: nil,
                        subdirectory: subdir)
    }
}
