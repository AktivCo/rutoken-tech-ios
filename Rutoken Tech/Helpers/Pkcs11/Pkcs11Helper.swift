//
//  Pkcs11Helper.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//

import Combine
import Foundation


protocol Pkcs11HelperProtocol {
    var tokens: AnyPublisher<[Pkcs11TokenProtocol], Never> { get }
    func startMonitoring() throws
}

enum Pkcs11Error: Error {
    case unknownError
}

class Pkcs11Helper: Pkcs11HelperProtocol {
    private var availableTokens: [CK_SLOT_ID: Pkcs11Token] = [:]
    private var tokenPublisher = CurrentValueSubject<[Pkcs11TokenProtocol], Never>([])
    public var tokens: AnyPublisher<[Pkcs11TokenProtocol], Never> {
        tokenPublisher.eraseToAnyPublisher()
    }

    private let engine: RtEngineWrapperProtocol

    init(with engine: RtEngineWrapperProtocol) {
        self.engine = engine
    }

    deinit {
        stop()
    }

    // MARK: - Public API
    func startMonitoring() throws {
        var initArgs = CK_C_INITIALIZE_ARGS()
        initArgs.flags = UInt(CKF_OS_LOCKING_OK)

        guard CKR_OK == C_Initialize(&initArgs) else {
            throw Pkcs11Error.unknownError
        }

        availableTokens = try getTokens()
        tokenPublisher.send(Array(availableTokens.values))

        DispatchQueue.global().async { [unowned self] in
            while true {
                var slot = CK_SLOT_ID()
                let rv = C_WaitForSlotEvent(0, &slot, nil)

                guard rv != CKR_CRYPTOKI_NOT_INITIALIZED else { return }
                guard rv == CKR_OK else { continue }

                availableTokens.removeValue(forKey: slot)

                if isPresent(slot), let token = Pkcs11Token(with: slot, engine) {
                    availableTokens[slot] = token
                }
                tokenPublisher.send(Array(availableTokens.values))
            }
        }
    }

    func stop() {
        C_Finalize(nil)
    }

    // MARK: - Private API
    private func getTokens() throws -> [CK_SLOT_ID: Pkcs11Token] {
        var ctr: UInt = 0
        var rv = C_GetSlotList(CK_BBOOL(CK_TRUE), nil, &ctr)
        guard rv == CKR_OK else {
            throw Pkcs11Error.unknownError
        }

        guard ctr != 0 else {
            return [:]
        }

        var slots = Array(repeating: CK_SLOT_ID(0), count: Int(ctr))
        rv = C_GetSlotList(CK_BBOOL(CK_TRUE), &slots, &ctr)
        guard rv == CKR_OK else {
            throw Pkcs11Error.unknownError
        }

        return slots.reduce([CK_SLOT_ID: Pkcs11Token]()) { (dict, slot) -> [CK_SLOT_ID: Pkcs11Token] in
            var dict = dict
            dict[slot] = Pkcs11Token(with: slot, engine)
            return dict
        }
    }

    private func isPresent(_ slot: CK_SLOT_ID) -> Bool {
        var slotInfo = CK_SLOT_INFO()
        let rv = C_GetSlotInfo(slot, &slotInfo)
        guard rv == CKR_OK else {
            return false
        }

        if slotInfo.flags & UInt(CKF_TOKEN_PRESENT) == 0 {
            return false
        }

        return true
    }
}
