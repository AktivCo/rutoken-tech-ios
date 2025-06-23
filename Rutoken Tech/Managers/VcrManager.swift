//
//  VcrManager.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 04.07.2024.
//

import Combine
import SwiftUI

import RtPcsc
import RtPcscWrapper


enum VcrError: Error {
    case general
}

protocol VcrManagerProtocol {
    func generateQrCode() async throws -> Image
    func unpairVcr(fingerprint: Data) throws
    func updateVcrStatus(readers: [RtReader]) async
    var vcrs: AnyPublisher<[VcrInfo], Never> { get }
    var didNewVcrConnected: AnyPublisher<Void, Never> { get }
}

class VcrManager: VcrManagerProtocol {
    private struct VcrPaired {
        let id: Data
        let name: String
    }

    private let pcscWrapper: RtPcscWrapper

    var vcrs: AnyPublisher<[VcrInfo], Never> {
        vcrsPublisher.share().eraseToAnyPublisher()
    }
    private var vcrsPublisher = CurrentValueSubject<[VcrInfo], Never>([])

    var didNewVcrConnected: AnyPublisher<Void, Never> {
        didNewVcrConnectedPublisher.eraseToAnyPublisher()
    }
    private var didNewVcrConnectedPublisher = PassthroughSubject<Void, Never>()

    init(pcscWrapper: RtPcscWrapper) {
        self.pcscWrapper = pcscWrapper
    }

    func updateVcrStatus(readers: [RtReader]) async {
        let newVcrs = await self.getPairedVcrs().asyncMap { vcr in
            return VcrInfo(id: vcr.id,
                           name: vcr.name,
                           isActive: await readers.filter({ $0.name.contains("VCR") }).async.contains(where: {
                guard let fingerprint = try? await pcscWrapper.getFingerprint(for: $0.name) else {
                    return false
                }

                return fingerprint == vcr.id
            }))
        }

        let oldVcrs = self.vcrsPublisher.value
        newVcrs.forEach { info in
            if oldVcrs.first(where: { info.id == $0.id }) == nil {
                self.didNewVcrConnectedPublisher.send()
            }
        }
        self.vcrsPublisher.send(newVcrs)
    }

    func generateQrCode() async throws -> Image {
        guard let strBase64 = generatePairingQR(),
              let data = Data(base64Encoded: strBase64),
              let image = Image(data: data) else {
            throw VcrError.general
        }
        return image
    }

    func unpairVcr(fingerprint: Data) throws {
        guard unpairVCR(fingerprint) else {
            throw VcrError.general
        }
        var value = self.vcrsPublisher.value
        value.removeAll { $0.id == fingerprint }
        self.vcrsPublisher.send(value)
    }

    private func getPairedVcrs() -> [VcrPaired] {
        return (listPairedVCR() as? [[String: Any]] ?? []).compactMap { info in
            guard let fingerprint = info["fingerprint"] as? Data,
                  let name = info["name"] as? String else {
                      return nil
                  }
            return VcrPaired(id: fingerprint, name: name)
        }
    }
}
