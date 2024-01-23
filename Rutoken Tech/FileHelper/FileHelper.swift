//
//  FileHelper.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 24.01.2024.
//

import Foundation


enum RtFile: String {
    case caKey = "ca.key"
    case caCert = "ca.pem"
    case bankKey = "bank.key"
    case bankCert = "bank.pem"
}

protocol FileHelperProtocol {
    func getContent(of file: RtFile) -> String?
}

class FileHelper: FileHelperProtocol {
    func getContent(of file: RtFile) -> String? {
        let arr = file.rawValue.components(separatedBy: ".")

        guard arr.count == 2,
              let filepath = Bundle.main.path(forResource: arr[0], ofType: arr[1]) else {
            return nil
        }

        return try? String(contentsOfFile: filepath)
    }
}
