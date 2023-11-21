//
//  CryptoManager.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//


protocol CryptoManagerProtocol {
    func getTokenInfo(tokenInterface: TokenInterface) async throws -> TokenInfo
}

enum CryptoManagerError: Error {
    case tokenNotFound
    case unknown
    case connectionLost
    case unsupportedDevice
    case nfcStopped
}

class CryptoManager: CryptoManagerProtocol {
    private var token: TokenProtocol?
    private let pkcs11Helper: Pkcs11HelperProtocol
    private let pcscHelper: PcscHelperProtocol

    init(pkcs11Helper: Pkcs11HelperProtocol, pcscHelper: PcscHelperProtocol) {
        self.pkcs11Helper = pkcs11Helper
        self.pcscHelper = pcscHelper
    }

    func getTokenInfo(tokenInterface: TokenInterface) throws -> TokenInfo {
        defer {
            if tokenInterface == .nfc {
                try? pcscHelper.stopNfc()
            }
        }
        do {
            if tokenInterface == .nfc {
                try pcscHelper.startNfc()
                try pcscHelper.waitForToken()
            }
            token = try pkcs11Helper.getConnectedToken(tokenType: tokenInterface)
            guard let token else {
                throw CryptoManagerError.tokenNotFound
            }
            return try token.getTokenInfo()
        } catch Pkcs11Error.connectionLost {
            throw CryptoManagerError.connectionLost
        } catch Pkcs11Error.tokenNotFound {
            throw CryptoManagerError.tokenNotFound
        } catch StartNfcError.unsupportedDevice {
            throw CryptoManagerError.unsupportedDevice
        } catch StartNfcError.cancelledByUser, StartNfcError.timeout {
            throw CryptoManagerError.nfcStopped
        } catch {
            throw CryptoManagerError.unknown
        }
    }
}
