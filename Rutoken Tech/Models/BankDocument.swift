//
//  BankDocument.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 11.03.2024.
//

import Foundation


struct BankDocument: Equatable {
    let name: String

    init(with name: String) {
        self.name = name
    }
}
