//
//  FileSourceHelper.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 28.06.2024.
//

import Foundation


fileprivate extension Bundle {
    static func getUrl(for file: String, in subdir: String? = nil) -> URL? {
        Bundle.main.url(forResource: file,
                        withExtension: nil,
                        subdirectory: subdir)
    }
}

enum SourceDir: String {
    case credentials
    case documents

    var rawValue: String {
        switch self {
        case .credentials: return "Credentials"
        case .documents: return "BankDocuments"
        }
    }
}

protocol FileSourceProtocol {
    func getUrl(for fileName: String, in sourceDir: SourceDir) -> URL?
}

class FileSourceHelper: FileSourceProtocol {
    func getUrl(for fileName: String, in sourceDir: SourceDir) -> URL? {
        Bundle.getUrl(for: fileName, in: sourceDir.rawValue)
    }
}
