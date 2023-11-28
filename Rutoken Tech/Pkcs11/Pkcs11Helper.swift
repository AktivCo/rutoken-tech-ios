//
//  Pkcs11Helper.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//


protocol Pkcs11HelperProtocol {
    func getConnectedToken(tokenType: TokenInterface) throws -> TokenProtocol
}

enum Pkcs11Error: Error {
    case unknownError
    case connectionLost
    case tokenNotFound
}

class Pkcs11Helper: Pkcs11HelperProtocol {
    private let engine: RtEngineWrapperProtocol

    private init(with engine: RtEngineWrapperProtocol) {
        self.engine = engine
        start()
    }

    deinit {
        stop()
    }

    func start() {
        var initArgs = CK_C_INITIALIZE_ARGS()
        initArgs.flags = UInt(CKF_OS_LOCKING_OK)

        let rv = C_Initialize(&initArgs)
        assert(rv == CKR_OK)
    }

    func stop() {
        C_Finalize(nil)
    }

    func getConnectedToken(tokenType: TokenInterface) throws -> TokenProtocol {
        return Token()
    }
}
