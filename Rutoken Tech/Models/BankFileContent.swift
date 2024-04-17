//
//  BankFileContent.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 28.03.2024.
//

import Foundation


enum BankFileContent {
    case singleFile(Data)
    case fileWithDetachedCMS(file: Data, cms: Data)
}
