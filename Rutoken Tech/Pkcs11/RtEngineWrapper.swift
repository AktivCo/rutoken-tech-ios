//
//  RtEngineWrapper.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 27.11.2023.
//

import Foundation


protocol RtEngineWrapperProtocol {}

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
        ENGINE_finish(rt_eng_get0_engine())

        rt_eng_unload_engine()
    }
}
