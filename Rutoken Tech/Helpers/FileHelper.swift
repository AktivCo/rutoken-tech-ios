//
//  FileHelper.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 24.01.2024.
//

import Foundation


protocol FileHelperProtocol {
    func clearDir(dirUrl: URL) throws
    func readFile(from url: URL) throws -> Data
    func saveFile(content: Data, url: URL) throws
}

enum FileHelperError: Error, Equatable {
    case generalError(UInt32, String?)
}

class FileHelper: FileHelperProtocol {
    // MARK: - Public API
    func clearDir(dirUrl: URL) throws {
        if FileManager.default.fileExists(atPath: dirUrl.path()) {
            do {
                try FileManager.default.removeItem(at: dirUrl)
            } catch {
                throw FileHelperError.generalError(#line, error.localizedDescription)
            }
        }
        do {
            try FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: false)
        } catch {
            throw FileHelperError.generalError(#line, error.localizedDescription)
        }
    }

    func saveFile(content: Data, url: URL) throws {
        do {
            try content.write(to: url)
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
}
