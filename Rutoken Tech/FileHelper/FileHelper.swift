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

enum BundleSubdir: String {
    case credentials = "Credentials"
    case bankDocuments = "BankDocuments"
}

protocol FileHelperProtocol {
    func clearTempDir() throws
    func readFile(from url: URL) throws -> Data
    func saveFileToTempDir(with name: String, content: Data) throws
    func copyFilesToTempDir(from source: [URL]) throws
}

func createBundleUrl(for file: String, in subdir: BundleSubdir) -> URL? {
    Bundle.main.url(forResource: file,
                    withExtension: nil,
                    subdirectory: subdir.rawValue)
}

class FileHelper: FileHelperProtocol {
    private let tempDir: URL

    init?(dirName: String) {
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        tempDir = documentsUrl.appendingPathComponent(dirName)
    }

    // MARK: - Public API
    func clearTempDir() throws {
        if FileManager.default.fileExists(atPath: tempDir.path()) {
            try FileManager.default.removeItem(at: tempDir)
        }
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: false)
    }

    func readFile(from url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }

    func copyFilesToTempDir(from source: [URL]) throws {
        for url in source {
            try FileManager.default.copyItem(at: url, to: tempDir.appendingPathComponent(url.lastPathComponent))
        }
    }

    func saveFileToTempDir(with name: String, content: Data) throws {
        try content.write(to: tempDir.appendingPathComponent(name))
    }
}

extension FileHelperProtocol {
    var documentListFileName: String {
        "documents.json"
    }
}
