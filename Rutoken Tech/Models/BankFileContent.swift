//
//  BankFileContent.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 28.03.2024.
//

import Foundation
import PDFKit


enum BankFileContent {
    case pdfDoc(PDFDocument)
    case base64(String)

    init?(type: FileType, content: Data) {
        switch type {
        case .plain:
            guard let doc = PDFDocument(data: content) else {
                return nil
            }
            self = .pdfDoc(doc)
        case .encrypted:
            guard let resultStr = String(data: content, encoding: .utf8) else {
                return nil
            }
            self = .base64(resultStr)
        }
    }
}
