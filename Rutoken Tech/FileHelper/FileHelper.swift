//
//  FileHelper.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 24.01.2024.
//

import Foundation


protocol FileHelperProtocol {
    func clearTempDir() throws
    func readFile(from url: URL) throws -> Data
    func saveFileToTempDir(with name: String, content: Data) throws
    func copyFilesToTempDir(from source: [URL]) throws
    func readDataFromTempDir(filename: String) throws -> Data
    func getUrlFromTempDir(for documentName: String) -> URL?
}

enum FileHelperError: Error, Equatable {
    case generalError(UInt32, String?)
}

class FileHelper: FileHelperProtocol {
    private let tempDir: URL

    init?(dirName: String) {
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        tempDir = documentsUrl.appending(path: dirName)
    }

    // MARK: - Public API
    func clearTempDir() throws {
        if FileManager.default.fileExists(atPath: tempDir.path()) {
            do {
                try FileManager.default.removeItem(at: tempDir)
            } catch {
                throw FileHelperError.generalError(#line, error.localizedDescription)
            }
        }
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: false)
        } catch {
            throw FileHelperError.generalError(#line, error.localizedDescription)
        }
    }

    func readFile(from url: URL) throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw FileHelperError.generalError(#line, error.localizedDescription)
        }
    }

    func copyFilesToTempDir(from source: [URL]) throws {
        for url in source {
            do {
                try FileManager.default.copyItem(at: url, to: tempDir.appending(path: url.lastPathComponent))
            } catch {
                throw FileHelperError.generalError(#line, error.localizedDescription)
            }
        }
    }

    func saveFileToTempDir(with name: String, content: Data) throws {
        do {
            try content.write(to: tempDir.appending(path: name))
        } catch {
            throw FileHelperError.generalError(#line, error.localizedDescription)
        }
    }

    func readDataFromTempDir(filename: String) throws -> Data {
        try readFile(from: tempDir.appending(path: filename))
    }

    func getUrlFromTempDir(for documentName: String) -> URL? {
        let url = tempDir.appending(path: documentName)
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) ? url : nil
    }
}
