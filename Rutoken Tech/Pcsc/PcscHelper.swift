//
//  PcscHelper.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 22.11.2023.
//


enum StartNfcError: Error {
    case unknown
    case timeout
    case cancelledByUser
    case unsupportedDevice
}

protocol PcscHelperProtocol {
    func startNfc() throws
    func stopNfc() throws
    func waitForToken() throws
}

class PcscHelper: PcscHelperProtocol {
    func stopNfc() throws {}

    func startNfc() throws {}

    func waitForToken() throws {}
}
