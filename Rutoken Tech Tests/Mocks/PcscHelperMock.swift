//
//  PcscHelperMock.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 22.11.2023.
//

import Combine

@testable import Rutoken_Tech


class PcscHelperMock: PcscHelperProtocol {
    func startNfc() throws {
        try startNfcCallback()
    }

    func stopNfc() throws {
        try stopNfcCallback()
    }

    func nfcExchangeIsStopped() -> AnyPublisher<Void, Never> {
        nfcExchangeIsStoppedCallback()
    }

    var startNfcCallback: () throws -> Void = {}
    var stopNfcCallback: () throws -> Void = {}
    var nfcExchangeIsStoppedCallback: () -> AnyPublisher<Void, Never> = {
        Empty<Void, Never>().eraseToAnyPublisher()
    }

    func getNfcCooldown() -> AsyncThrowingStream<UInt, Error> {
        nfcCooldownCounter
    }

    var nfcCooldownCounter: AsyncThrowingStream<UInt, Error> = {
        AsyncThrowingStream { con in
            con.finish()
        }
    }()
}
