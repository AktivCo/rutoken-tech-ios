//
//  Pkcs11Helper.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//

import Combine
import Foundation


protocol Pkcs11HelperProtocol {
    var tokens: AnyPublisher<[TokenProtocol], Never> { get }
}

enum Pkcs11Error: Error {
    case unknownError
    case connectionLost
    case tokenNotFound
}

class Pkcs11Helper: Pkcs11HelperProtocol {
    private var availableTokens: [CK_SLOT_ID: Token] = [:]
    private var tokenPublisher = CurrentValueSubject<[TokenProtocol], Never>([])
    public var tokens: AnyPublisher<[TokenProtocol], Never> {
        tokenPublisher.eraseToAnyPublisher()
    }

    private let engine: RtEngineWrapperProtocol

    init(with engine: RtEngineWrapperProtocol) {
        self.engine = engine

        start()
    }

    deinit {
        stop()
    }

    // MARK: - Public API
    func start() {
        var initArgs = CK_C_INITIALIZE_ARGS()
        initArgs.flags = UInt(CKF_OS_LOCKING_OK)

        let rv = C_Initialize(&initArgs)
        assert(rv == CKR_OK)

        DispatchQueue.global().async { [unowned self] in
            availableTokens = getTokens()
            tokenPublisher.send(Array(availableTokens.values))

            while true {
                var slot = CK_SLOT_ID()
                let rv = C_WaitForSlotEvent(0, &slot, nil)

                guard rv != CKR_CRYPTOKI_NOT_INITIALIZED else { return }
                guard rv == CKR_OK else { continue }

                availableTokens.removeValue(forKey: slot)

                if isPresent(slot), let token = Token(with: slot, engine) {
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
    private func getTokens() -> [CK_SLOT_ID: Token] {
        var ctr: UInt = 0
        var rv = C_GetSlotList(CK_BBOOL(CK_TRUE), nil, &ctr)
        guard rv == CKR_OK else {
            return [:]
        }

        guard ctr != 0 else {
            return [:]
        }

        var slots = Array(repeating: CK_SLOT_ID(0), count: Int(ctr))
        rv = C_GetSlotList(CK_BBOOL(CK_TRUE), &slots, &ctr)
        guard rv == CKR_OK else {
            return [:]
        }

        return slots.reduce([CK_SLOT_ID: Token]()) { (dict, slot) -> [CK_SLOT_ID: Token] in
            var dict = dict
            dict[slot] = Token(with: slot, engine)
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
