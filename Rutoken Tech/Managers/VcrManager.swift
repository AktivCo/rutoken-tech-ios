//
//  VcrManager.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 04.07.2024.
//

import SwiftUI

import RtPcsc


enum VcrError: Error {
    case general
}

protocol VcrManagerProtocol {
    func generateQrCode() async throws -> Image
}

class VcrManager: VcrManagerProtocol {
    func generateQrCode() async throws -> Image {
        guard let strBase64 = generatePairingQR(),
              let data = Data(base64Encoded: strBase64),
              let image = Image(data: data) else {
            throw VcrError.general
        }
        return image
    }
}
