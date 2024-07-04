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

    var tokens: AnyPublisher<[Pkcs11TokenProtocol], Never> {
        tokenPublisher.eraseToAnyPublisher()
    }

    var tokenPublisher = CurrentValueSubject<[Pkcs11TokenProtocol], Never>([])

    func isPresent(_ slot: CK_SLOT_ID) -> Bool {
        isPresentCallback(slot)
    }

    var isPresentCallback: (CK_SLOT_ID) -> Bool = { _ in true }
}
