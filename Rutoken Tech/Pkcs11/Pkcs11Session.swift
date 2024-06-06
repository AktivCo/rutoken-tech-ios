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

    deinit {
        C_CloseSession(handle)
    }

    func login(pin: String) throws {
        var rawPin: [UInt8] = Array(pin.utf8)
        let rv = C_Login(handle, CK_USER_TYPE(CKU_USER), &rawPin, CK_ULONG(rawPin.count))
        guard rv == CKR_OK || rv == CKR_USER_ALREADY_LOGGED_IN else {
            switch rv {
            case CKR_PIN_INCORRECT:
                throw Pkcs11TokenError.incorrectPin(attemptsLeft: try getPinAttempts())
            case CKR_PIN_LOCKED:
                throw Pkcs11TokenError.lockedPin
            default:
                throw Pkcs11TokenError.generalError
            }
        }
    }

    func logout() {
        C_Logout(handle)
    }

    func findObjects(_ attributes: [CK_ATTRIBUTE]) throws -> [Pkcs11Object] {
        var template = attributes
        var rv = C_FindObjectsInit(handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw rv == CKR_DEVICE_REMOVED ? Pkcs11TokenError.tokenDisconnected: Pkcs11TokenError.generalError
        }
        defer {
            C_FindObjectsFinal(handle)
        }

        var count: CK_ULONG = 0
        // You can define your own number of required objects.
        let maxCount: CK_ULONG = 16
        var objects: [CK_OBJECT_HANDLE] = []
        repeat {
            var handles: [CK_OBJECT_HANDLE] = Array(repeating: 0x00, count: Int(maxCount))

            rv = C_FindObjects(handle, &handles, maxCount, &count)
            guard rv == CKR_OK else {
                throw rv == CKR_DEVICE_REMOVED ? Pkcs11TokenError.tokenDisconnected: Pkcs11TokenError.generalError
            }

            objects += handles.prefix(Int(count))
        } while count == maxCount

        return objects.map { Pkcs11Object(with: $0, self) }
    }

    private func getPinAttempts() throws -> UInt {
        var exInfo = CK_TOKEN_INFO_EXTENDED()
        exInfo.ulSizeofThisStructure = UInt(MemoryLayout.size(ofValue: exInfo))
        let rv = C_EX_GetTokenInfoExtended(slot, &exInfo)
        guard rv == CKR_OK else {
            throw Pkcs11TokenError.generalError
        }

        return exInfo.ulUserRetryCountLeft
    }
}
