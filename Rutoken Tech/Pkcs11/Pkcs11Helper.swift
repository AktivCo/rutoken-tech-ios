//
//  Pkcs11Helper.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//

import Combine
import Foundation


protocol Pkcs11HelperProtocol {
    func getToken(with type: ConnectionType) throws -> TokenProtocol
}

enum Pkcs11Error: Error {
    case unknownError
    case connectionLost
    case tokenNotFound
}

class Pkcs11Helper: Pkcs11HelperProtocol {
    private var tokens = [Token]()

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

        assert(C_Initialize(&initArgs) == CKR_OK)

        DispatchQueue.global().async { [unowned self] in
            guard let availableTokens = try? getTokens() else {
                return
            }

            tokens = availableTokens
            while true {
                var slot = CK_SLOT_ID()
                let rv = C_WaitForSlotEvent(0, &slot, nil)

                guard rv != CKR_CRYPTOKI_NOT_INITIALIZED else { return }
                guard rv == CKR_OK else { continue }

                tokens.removeAll(where: { $0.slot == slot })

                if isPresent(slot), let token = Token(with: slot) {
                    tokens.append(token)
                }
            }
        }
    }

    func stop() {
        C_Finalize(nil)
    }

    func getToken(with type: ConnectionType) throws -> TokenProtocol {
        guard let token = tokens.first(where: { $0.connectionType == type }) else {
            throw Pkcs11Error.tokenNotFound
        }
        return token
    }

    // MARK: - Private API
    private func getTokens() throws -> [Token] {
        var ctr: UInt = 0
        var rv = C_GetSlotList(CK_BBOOL(CK_TRUE), nil, &ctr)
        guard rv == CKR_OK else {
            throw Pkcs11Error.unknownError
        }

        guard ctr != 0 else {
            throw Pkcs11Error.unknownError
        }

        var slots = Array(repeating: CK_SLOT_ID(0), count: Int(ctr))
        rv = C_GetSlotList(CK_BBOOL(CK_TRUE), &slots, &ctr)
        guard rv == CKR_OK else {
            throw Pkcs11Error.unknownError
        }

        return slots.compactMap { Token(with: $0) }
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
