//
//  Pkcs11HelperMock.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 22.11.2023.
//

import Combine

@testable import Rutoken_Tech


class Pkcs11HelperMock: Pkcs11HelperProtocol {
    func startMonitoring() throws {
        try startMonitoringCallback()
    }

    var startMonitoringCallback: () throws -> Void = {}

    var tokens: AnyPublisher<[TokenProtocol], Never> {
        tokenPublisher.eraseToAnyPublisher()
    }

    var tokenPublisher = CurrentValueSubject<[TokenProtocol], Never>([])
}
