//
//  Image+Data.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 04.07.2024.
//

import SwiftUI


extension Image {
    init?(data: Data) {
        guard let image = UIImage(data: data) else { return nil }
        self = .init(uiImage: image)
    }
}
