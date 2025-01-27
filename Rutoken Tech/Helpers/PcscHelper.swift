//
//  PcscHelper.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 22.11.2023.
//

import Combine
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
    func startNfc() throws
    func stopNfc() throws
    func nfcExchangeIsStopped() -> AnyPublisher<Void, Never>
    func getNfcCooldown() -> AsyncThrowingStream<UInt, Error>
}

class PcscHelper: PcscHelperProtocol {
    private var pcscWrapper: RtPcscWrapper
    private var cancellable = Set<AnyCancellable>()
    private var readers: [RtReader] = []

    init(pcscWrapper: RtPcscWrapper) {
        self.pcscWrapper = pcscWrapper

        pcscWrapper.readers
            .receive(on: DispatchQueue.main)
            .assign(to: \.readers, on: self)
            .store(in: &cancellable)

        pcscWrapper.start()
    }

    func getNfcCooldown() -> AsyncThrowingStream<UInt, Error> {
        AsyncThrowingStream { continuation in
            guard let reader = readers.first(where: { $0.type == .nfc || $0.type == .vcr }) else {
                continuation.finish(throwing: PcscHelperError.general)
                return
            }

            Task {
                do {
                    var cooldownLeft: UInt = 1
                    while cooldownLeft > 0 {
                        try? await Task.sleep(for: .seconds(0.1))
                        cooldownLeft = try self.pcscWrapper.getNfcCooldown(for: reader.name)
                        continuation.yield(cooldownLeft)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: PcscHelperError.general)
                }
            }
        }
    }

    func stopNfc() throws {
        guard let reader = readers.first(where: { $0.type == .nfc || $0.type == .vcr }) else {
            throw NfcError.generalError
        }

        do {
            try pcscWrapper.stopNfc(onReader: reader.name, withMessage: NfcMessages.stopNfc.rawValue)
        } catch {
            throw NfcError.unknown
        }
    }

    func startNfc() throws {
        guard let reader = readers.first(where: { $0.type == .nfc || $0.type == .vcr }) else {
            throw NfcError.generalError
        }
        do {
            try pcscWrapper.startNfc(onReader: reader.name, waitMessage: NfcMessages.startNfc.rawValue, workMessage: NfcMessages.workOn.rawValue)
        } catch RtReaderError.nfcIsStopped(.cancelledByUser) {
            throw NfcError.cancelledByUser
        } catch RtReaderError.nfcIsStopped(.timeout) {
            throw NfcError.timeout
        } catch {
            throw NfcError.unknown
        }
    }

    func nfcExchangeIsStopped() -> AnyPublisher<Void, Never> {
        guard let reader = readers.first(where: { $0.type == .vcr || $0.type == .nfc }) else {
            return Just(()).eraseToAnyPublisher()
        }

        return pcscWrapper.nfcExchangeIsStopped(for: reader.name)
    }
}
