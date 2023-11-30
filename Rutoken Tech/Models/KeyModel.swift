//
//  KeyModel.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 30.11.2023.
//

import Foundation


enum KeyAlgorithm {
    case gostR3410_2012_256
}

struct KeyModel: Equatable {
    let ckaId: String
    let type: KeyAlgorithm
}
