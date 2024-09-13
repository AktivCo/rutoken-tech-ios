//
//  KeyModel.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 30.11.2023.
//

import Foundation


struct KeyModel: Equatable {
    let ckaId: Data
    let type: Pkcs11KeyAlgorithm
}
