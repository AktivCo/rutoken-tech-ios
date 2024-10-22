//
//  Token.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//

import Foundation


protocol TokenProtocol {
    var label: String { get }
    var serial: String { get }
    var model: TokenModel { get }

    var currentInterface: TokenInterface { get }
    var supportedInterfaces: Set<TokenInterface> { get }

    func login(with pin: String) throws
    func logout()

    func generateKeyPair(with id: String) throws

    func enumerateCerts(by id: String?) throws -> [Pkcs11ObjectProtocol]
    func enumerateKeys(by id: String?, with type: KeyAlgorithm?) throws -> [Pkcs11KeyPair]

    func getWrappedKey(with id: String) throws -> WrappedPointer<OpaquePointer>

    func importCert(_ cert: Data, for id: String) throws
}

enum TokenError: Error, Equatable {
    case incorrectPin(attemptsLeft: UInt)
    case lockedPin
    case generalError
    case tokenDisconnected
    case keyNotFound
}

class Token: TokenProtocol, Identifiable {
    private let slot: CK_SLOT_ID
    private let session: Pkcs11Session
    private let engine: RtEngineWrapperProtocol

    let label: String
    let serial: String
    let model: TokenModel
    let currentInterface: TokenInterface
    let supportedInterfaces: Set<TokenInterface>

    init?(with slot: CK_SLOT_ID, _ engine: RtEngineWrapperProtocol) {
        self.slot = slot
        self.engine = engine

        var tokenInfo = CK_TOKEN_INFO()
        var rv = C_GetTokenInfo(slot, &tokenInfo)
        guard rv == CKR_OK else {
            return nil
        }

        // MARK: Get serial number
        guard let hexSerial = String.getFrom(tokenInfo.serialNumber),
              let decimalSerial = Int(hexSerial.trimmingCharacters(in: .whitespacesAndNewlines), radix: 16) else {
            return nil
        }
        self.serial = String(format: "%0.10d", decimalSerial)

        // MARK: Get label
        guard let label = String.getFrom(tokenInfo.label)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        self.label = label

        // MARK: Get supported interfaces
        guard let session = Pkcs11Session(slot: self.slot) else {
            return nil
        }
        self.session = session

        guard let (currentInterfaceBits, supportedInterfacesBits) = Token.getTokenInterfaces(session: session.handle) else {
            return nil
        }

        guard let currentInterface = TokenInterface(currentInterfaceBits) else {
            return nil
        }
        self.currentInterface = currentInterface

        self.supportedInterfaces = Set([TokenInterface](bits: supportedInterfacesBits))

        // MARK: Get model
        var extendedTokenInfo = CK_TOKEN_INFO_EXTENDED()
        extendedTokenInfo.ulSizeofThisStructure = UInt(MemoryLayout.size(ofValue: extendedTokenInfo))
        rv = C_EX_GetTokenInfoExtended(slot, &extendedTokenInfo)
        guard rv == CKR_OK else {
            return nil
        }

        guard let model = TokenModel(tokenInfo.hardwareVersion, tokenInfo.firmwareVersion,
                                     extendedTokenInfo.ulTokenClass, supportedInterfaces: supportedInterfaces) else {
            return nil
        }
        self.model = model
    }

    // MARK: - Public API
    func login(with pin: String) throws {
        try checkingToken {
            try session.login(pin: pin)
        }
    }

    func logout() {
        session.logout()
    }

    func enumerateCerts(by id: String?) throws -> [Pkcs11ObjectProtocol] {
        var certs: [Pkcs11Object] = []
        var certTemplate = [
            AttributeType.objectClass(.cert),
            .attrTrue(CKA_TOKEN),
            .certX509(&certTypeX509, UInt(MemoryLayout.size(ofValue: certTypeX509)))
        ].map { $0.attr }

        var idPointer: WrappedPointer<UnsafeMutablePointer<UInt8>>
        if let id {
            idPointer = id.createPointer()
            certTemplate.append(AttributeType.id(idPointer.pointer, UInt(id.count)).attr)
        }

        let certObjects = try Token.findObjects(certTemplate, in: session.handle)

        for obj in certObjects {
            certs.append(Pkcs11Object(with: obj, session))
        }
        return certs
    }

    func enumerateKeys(by id: String?, with type: KeyAlgorithm?) throws -> [Pkcs11KeyPair] {
        var keyPairs: [Pkcs11KeyPair] = []

        // MARK: Prepare key templates
        var pubKeyTemplate = [
            AttributeType.objectClass(.publicKey),
            .attrTrue(CKA_TOKEN),
            .attrFalse(CKA_PRIVATE)
        ].map { $0.attr }
        var privateKeyTemplate = [
            AttributeType.objectClass(.privateKey),
            .attrTrue(CKA_TOKEN),
            .attrTrue(CKA_PRIVATE)
        ].map { $0.attr }

        switch type {
        case .gostR3410_2012_256:
            pubKeyTemplate.append(
                AttributeType.keyType(&keyTypeGostR3410_2012_256,
                                      UInt(MemoryLayout.size(ofValue: keyTypeGostR3410_2012_256))).attr
            )
            privateKeyTemplate.append(
                AttributeType.keyType(&keyTypeGostR3410_2012_256,
                                      UInt(MemoryLayout.size(ofValue: keyTypeGostR3410_2012_256))).attr
            )
        case .none: break
        }

        var idPointer: WrappedPointer<UnsafeMutablePointer<UInt8>>
        if let id {
            idPointer = id.createPointer()
            pubKeyTemplate.append(AttributeType.id(idPointer.pointer, UInt(id.count)).attr)
            privateKeyTemplate.append(AttributeType.id(idPointer.pointer, UInt(id.count)).attr)
        }

        // MARK: Find public keys
        let pubKeyObjects = try Token.findObjects(pubKeyTemplate, in: session.handle)

        var publicKeys: [Pkcs11Object] = []
        for obj in pubKeyObjects {
            publicKeys.append(Pkcs11Object(with: obj, session))
        }

        // MARK: Find private keys
        let privateKeyObjects = try Token.findObjects(privateKeyTemplate, in: session.handle)

        for obj in privateKeyObjects {
            let privateKey = Pkcs11Object(with: obj, session)
            if let pubKey = publicKeys.first(where: { $0.id == privateKey.id }) {
                keyPairs.append(.init(pubKey: pubKey, privateKey: privateKey))
            }
        }

        return keyPairs
    }

    func getWrappedKey(with id: String) throws -> WrappedPointer<OpaquePointer> {
        guard let keyPair = try enumerateKeys(by: id, with: .gostR3410_2012_256).first else {
            throw TokenError.keyNotFound
        }

        guard let evpPKey = try? engine.wrapKeys(with: session.handle,
                                                 privateKeyHandle: keyPair.privateKey.handle,
                                                 pubKeyHandle: keyPair.pubKey.handle) else {
            throw TokenError.generalError
        }
        return WrappedPointer(ptr: evpPKey, EVP_PKEY_free)
    }

    func generateKeyPair(with id: String) throws {
        var publicKey = CK_OBJECT_HANDLE()
        var privateKey = CK_OBJECT_HANDLE()

        let idPointer = id.createPointer()
        var publicKeyTemplate = [
            AttributeType.objectClass(.publicKey),
            .id(idPointer.pointer, UInt(id.count)),
            .keyType(&keyTypeGostR3410_2012_256, UInt(MemoryLayout.size(ofValue: keyTypeGostR3410_2012_256))),
            .attrTrue(CKA_TOKEN), .attrFalse(CKA_PRIVATE),
            .gostR3410_2012_256_params, .gostR3411_2012_256_params
        ].map { $0.attr }

        var privateKeyTemplate = [
            AttributeType.objectClass(.privateKey),
            .id(idPointer.pointer, UInt(id.count)),
            .keyType(&keyTypeGostR3410_2012_256, UInt(MemoryLayout.size(ofValue: keyTypeGostR3410_2012_256))),
            .attrTrue(CKA_TOKEN), .attrTrue(CKA_PRIVATE), .attrTrue(CKA_DERIVE),
            .gostR3410_2012_256_params, .gostR3411_2012_256_params
        ].map { $0.attr }

        var gostR3410_2012_256KeyPairGenMech: CK_MECHANISM = CK_MECHANISM(mechanism: CKM_GOSTR3410_KEY_PAIR_GEN, pParameter: nil, ulParameterLen: 0)

        let rv = C_GenerateKeyPair(session.handle, &gostR3410_2012_256KeyPairGenMech,
                                   &publicKeyTemplate, CK_ULONG(publicKeyTemplate.count),
                                   &privateKeyTemplate, CK_ULONG(privateKeyTemplate.count),
                                   &publicKey, &privateKey)
        guard rv == CKR_OK else {
            throw rv == CKR_DEVICE_REMOVED ? TokenError.tokenDisconnected: TokenError.generalError
        }
    }

    func deleteKeyPair(with id: String) throws {
        let idPointer = id.createPointer()
        let template = [
            AttributeType.id(idPointer.pointer, UInt(id.count)),
            .keyType(&keyTypeGostR3410_2012_256, UInt(MemoryLayout.size(ofValue: keyTypeGostR3410_2012_256)))
        ].map { $0.attr }

        let objects = try Token.findObjects(template, in: session.handle)

        guard !objects.isEmpty else {
            throw TokenError.generalError
        }

        for obj in objects {
            let rv = C_DestroyObject(session.handle, obj)
            guard rv == CKR_OK else {
                throw TokenError.generalError
            }
        }
    }

    func importCert(_ cert: Data, for id: String) throws {
        guard (try enumerateKeys(by: id, with: .gostR3410_2012_256).first) != nil else {
            throw TokenError.generalError
        }
        try cert.withUnsafeBytes { ptr in
            let idPointer = id.createPointer()
            // MARK: Prepare cert template
            var certTemplate = [
                AttributeType.value(UnsafeMutableRawPointer(mutating: ptr.baseAddress), UInt(cert.count)),
                .objectClass(.cert),
                .id(idPointer.pointer, UInt(id.count)),
                .attrTrue(CKA_TOKEN),
                .attrFalse(CKA_PRIVATE),
                .certX509(&certTypeX509, UInt(MemoryLayout.size(ofValue: certTypeX509))),
                .certCategory(&certCategoryUser, UInt(MemoryLayout.size(ofValue: certCategoryUser)))
            ].map { $0.attr }

            var certHandle = CK_OBJECT_HANDLE()
            let rv = C_CreateObject(session.handle, &certTemplate, CK_ULONG(certTemplate.count), &certHandle)
            guard rv == CKR_OK else {
                throw rv == CKR_DEVICE_REMOVED ? TokenError.tokenDisconnected: TokenError.generalError
            }
        }
    }

    // MARK: - Private API
    private func checkingToken<T>(_ closure: () throws -> T) throws -> T {
        do {
            return try closure()
        } catch let error {
            var slotInfo = CK_SLOT_INFO()
            let rv = C_GetSlotInfo(slot, &slotInfo)
            guard rv == CKR_OK,
                  slotInfo.flags & UInt(CKF_TOKEN_PRESENT) != 0 else {
                throw TokenError.tokenDisconnected
            }
            throw error
        }
    }

    class private func getTokenInterfaces(session: CK_SESSION_HANDLE) -> (CK_ULONG, CK_ULONG)? {
        let objectTemplate = [AttributeType.objectClass(.hwFeature), AttributeType.hwFeatureType].map { $0.attr }

        guard let handle = try? Token.findObjects(objectTemplate, in: session).first else {
            return nil
        }

        let valueSize: CK_ULONG = 0
        let currentInterfaceAttr = CK_ATTRIBUTE(type: CK_ATTRIBUTE_TYPE(CKA_VENDOR_CURRENT_TOKEN_INTERFACE),
                                                pValue: nil,
                                                ulValueLen: valueSize)
        let supportedInterfaceAttr = CK_ATTRIBUTE(type: CK_ATTRIBUTE_TYPE(CKA_VENDOR_SUPPORTED_TOKEN_INTERFACE),
                                                  pValue: nil,
                                                  ulValueLen: valueSize)

        var template = [currentInterfaceAttr, supportedInterfaceAttr]
        var rv = C_GetAttributeValue(session, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            return nil
        }

        for i in 0..<template.count {
            template[i].pValue = UnsafeMutableRawPointer.allocate(byteCount: Int(template[i].ulValueLen), alignment: 1)
        }
        defer {
            for i in 0..<template.count {
                template[i].pValue.deallocate()
            }
        }

        rv = C_GetAttributeValue(session, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            return nil
        }

        return (UnsafeRawBufferPointer(start: template[0].pValue.assumingMemoryBound(to: UInt8.self),
                                       count: Int(template[0].ulValueLen)).load(as: CK_ULONG.self),
                UnsafeRawBufferPointer(start: template[1].pValue.assumingMemoryBound(to: UInt8.self),
                                       count: Int(template[1].ulValueLen)).load(as: CK_ULONG.self))
    }

    class private func findObjects(_ attributes: [CK_ATTRIBUTE], in session: CK_SESSION_HANDLE) throws -> [CK_OBJECT_HANDLE] {
        var template = attributes
        var rv = C_FindObjectsInit(session, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw rv == CKR_DEVICE_REMOVED ? TokenError.tokenDisconnected: TokenError.generalError
        }
        defer {
            C_FindObjectsFinal(session)
        }

        var count: CK_ULONG = 0
        // You can define your own number of required objects.
        let maxCount: CK_ULONG = 16
        var objects: [CK_OBJECT_HANDLE] = []
        repeat {
            var handles: [CK_OBJECT_HANDLE] = Array(repeating: 0x00, count: Int(maxCount))

            rv = C_FindObjects(session, &handles, maxCount, &count)
            guard rv == CKR_OK else {
                throw rv == CKR_DEVICE_REMOVED ? TokenError.tokenDisconnected: TokenError.generalError
            }

            objects += handles.prefix(Int(count))
        } while count == maxCount

        return objects
    }
}
