//
//  Pkcs11Session.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2024-02-02.
//

import Foundation


class Pkcs11Session {
    private let slot: CK_SLOT_ID
    private(set) var handle = CK_SESSION_HANDLE(NULL_PTR)

    init?(slot: CK_SLOT_ID) {
        self.slot = slot

        guard C_OpenSession(slot,
                            CK_FLAGS(CKF_SERIAL_SESSION | CKF_RW_SESSION),
                            nil,
                            nil,
                            &self.handle) == CKR_OK else {
            return nil
        }
    }

    func login(pin: String) throws {
        var rawPin: [UInt8] = Array(pin.utf8)
        let rv = C_Login(handle, CK_USER_TYPE(CKU_USER), &rawPin, CK_ULONG(rawPin.count))
        guard rv == CKR_OK || rv == CKR_USER_ALREADY_LOGGED_IN else {
            switch rv {
            case CKR_PIN_INCORRECT:
                throw TokenError.incorrectPin(attemptsLeft: try getPinAttempts())
            case CKR_PIN_LOCKED:
                throw TokenError.lockedPin
            default:
                throw TokenError.generalError
            }
        }
    }

    func logout() {
        C_Logout(handle)
    }

    deinit {
        C_CloseSession(handle)
    }

    private func getPinAttempts() throws -> UInt {
        var exInfo = CK_TOKEN_INFO_EXTENDED()
        exInfo.ulSizeofThisStructure = UInt(MemoryLayout.size(ofValue: exInfo))
        let rv = C_EX_GetTokenInfoExtended(slot, &exInfo)
        guard rv == CKR_OK else {
            throw TokenError.generalError
        }

        return exInfo.ulUserRetryCountLeft
    }
}
