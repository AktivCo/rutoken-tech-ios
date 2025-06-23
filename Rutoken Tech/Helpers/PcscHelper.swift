//
//  PcscHelper.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 22.11.2023.
//

import Foundation

import RtMock
import RtPcscWrapper


enum PcscHelperError: Error {
    case general
}

enum NfcError: Error {
    case unknown
    case generalError
    case timeout
    case cancelledByUser
}

@RtMock
protocol PcscHelperProtocol {
    func startNfc() async throws -> AsyncStream<RtNfcSearchStatus>
    func stopNfc() async throws
    func getNfcCooldown() -> AsyncThrowingStream<UInt, Error>
}

class PcscHelper: PcscHelperProtocol {
    private var pcscWrapper: RtPcscWrapper
    private var nfcReader: RtReader?
    private var vcrManager: VcrManagerProtocol?

    init(pcscWrapper: RtPcscWrapper, vcrManager: VcrManagerProtocol?) {
        self.pcscWrapper = pcscWrapper
        self.vcrManager = vcrManager

        Task {
            guard let stream = await pcscWrapper.start() else {
                fatalError()
            }
            await vcrManager?.updateVcrStatus(readers: [])
            for await element in stream {
                await vcrManager?.updateVcrStatus(readers: element)
                nfcReader = element.first(where: { $0.type == .nfc || $0.type == .vcr })
            }
        }
    }

    func getNfcCooldown() -> AsyncThrowingStream<UInt, Error> {
        AsyncThrowingStream { continuation in
            guard let nfcReader else {
                continuation.finish(throwing: PcscHelperError.general)
                return
            }

            Task {
                do {
                    var cooldownLeft: UInt = 1
                    while cooldownLeft > 0 {
                        try? await Task.sleep(for: .seconds(0.1))
                        cooldownLeft = try await self.pcscWrapper.getNfcCooldown(for: nfcReader.name)
                        continuation.yield(cooldownLeft)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: PcscHelperError.general)
                }
            }
        }
    }

    func stopNfc() async throws {
        guard let nfcReader else {
            throw NfcError.generalError
        }

        do {
            try await pcscWrapper.stopNfc(onReader: nfcReader.name, withMessage: NfcMessages.stopNfc.rawValue)
        } catch {
            throw NfcError.unknown
        }
    }

    func startNfc() async throws -> AsyncStream<RtNfcSearchStatus> {
        guard let nfcReader else {
            throw NfcError.generalError
        }

        return await pcscWrapper.startNfcExchange(onReader: nfcReader.name, waitMessage: NfcMessages.startNfc.rawValue,
                                                  workMessage: NfcMessages.workOn.rawValue)
    }
}
