//
//  BankFileContent.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 28.03.2024.
//

import Foundation


struct BankFileContent {
    let data: Data
    let cmsData: Data?

    init(data: Data, cmsData: Data? = nil) {
        self.data = data
        self.cmsData = cmsData
    }
}
