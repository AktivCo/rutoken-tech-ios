//
//  RtEngineWrapper.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 27.11.2023.
//

import Foundation


enum RtEngingeError: Error {
    case generalError
}

protocol RtEngineWrapperProtocol {
    func wrapKeys(with session: CK_SESSION_HANDLE, privateKeyHandle: CK_OBJECT_HANDLE, pubKeyHandle: CK_OBJECT_HANDLE) throws -> OpaquePointer
}

class RtEngineWrapper: RtEngineWrapperProtocol {
    private let rtengine: OpaquePointer

    init() {
        let ENGINE_METHOD_ALL: UInt32 = 0xFFFF
        let ENGINE_METHOD_RAND: UInt32 = 0x0008

        var r = rt_eng_load_engine()
        assert(r == 1)

        rtengine = rt_eng_get0_engine()
        ENGINE_init(rtengine)

        r = ENGINE_set_default(rtengine, ENGINE_METHOD_ALL - ENGINE_METHOD_RAND)
        assert(r == 1)
    }

    deinit {
        ENGINE_unregister_pkey_asn1_meths(rtengine)
        ENGINE_unregister_pkey_meths(rtengine)
        ENGINE_unregister_digests(rtengine)
        ENGINE_unregister_ciphers(rtengine)
        ENGINE_finish(rtengine)

        rt_eng_unload_engine()
    }

    func wrapKeys(with session: CK_SESSION_HANDLE,
                  privateKeyHandle: CK_OBJECT_HANDLE,
                  pubKeyHandle: CK_OBJECT_HANDLE) throws -> OpaquePointer {
        // MARK: - wrap session
        var funcListPtr: UnsafeMutablePointer<CK_FUNCTION_LIST>?
        let rv = C_GetFunctionList(&funcListPtr)
        guard rv == CKR_OK else {
            throw Pkcs11TokenError.generalError
        }

        guard let wrappedSession = rt_eng_p11_session_wrap(funcListPtr, session, 0, nil) else {
            throw Pkcs11TokenError.generalError
        }
        defer {
            rt_eng_p11_session_free(wrappedSession)
        }

        // MARK: - wrap keys
        guard let evpPKey = rt_eng_p11_key_pair_wrap(wrappedSession, privateKeyHandle, pubKeyHandle) else {
            throw RtEngingeError.generalError
        }
        return evpPKey
    }
}
