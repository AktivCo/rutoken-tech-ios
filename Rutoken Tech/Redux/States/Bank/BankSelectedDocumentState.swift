//
//  BankSelectedDocumentState.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 15.04.2024.
//

import Foundation


struct BankSelectedDocumentState {
    var metadata: BankDocument?
    var docContent: BankFileContent?
    var urlsForShare: [URL] = []
}
