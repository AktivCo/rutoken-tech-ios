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
    func resetTempDir() throws
}

class FileHelper: FileHelperProtocol {
    private let tempDir: URL

    init?(dirName: String) {
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        tempDir = documentsUrl.appendingPathComponent(dirName)
        do {
            try resetTempDir()
        } catch {
            fatalError("Failed to initialize FileHelper with error: \(error.localizedDescription)")
        }
    }

    func resetTempDir() throws {
        if FileManager.default.fileExists(atPath: tempDir.path()) {
            try FileManager.default.removeItem(at: tempDir)
        }
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: false)
    }

    func getContent(of file: RtFile) -> String? {
        let arr = file.rawValue.components(separatedBy: ".")

        guard arr.count == 2,
              let filepath = Bundle.main.path(forResource: arr[0], ofType: arr[1]) else {
            return nil
        }

        return try? String(contentsOfFile: filepath)
    }
}
