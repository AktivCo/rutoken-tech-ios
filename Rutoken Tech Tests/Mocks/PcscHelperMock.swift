//
//  PcscHelperMock.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 22.11.2023.
//

@testable import Rutoken_Tech


class PcscHelperMock: PcscHelperProtocol {
    func startNfc() throws {
        try startNfcCallback()
    }

    func stopNfc() throws {
        try stopNfcCallback()
    }

    func waitForToken() throws {
        try waitForTokenCallback()
    }

    var startNfcCallback: () throws -> Void = {}
    var stopNfcCallback: () throws -> Void = {}
    var waitForTokenCallback: () throws -> Void = {}

}
