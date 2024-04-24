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

        if tokenInfo.firmwareVersion.major >= 32 {
            guard let modelName = Token.getTokenVendorModel(session: session.handle) else {
                return nil
            }
            self.model = .rutokenSelfIdentify(modelName)
        } else {
            guard let model = TokenModel(tokenInfo.hardwareVersion, tokenInfo.firmwareVersion,
                                         extendedTokenInfo, supportedInterfaces: supportedInterfaces) else {
                return nil
            }
            self.model = model
        }
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
        var certTemplate: [PkcsAttribute] = [
            ULongAttribute(type: .classObject, value: CKO_CERTIFICATE),
            BoolAttribute(type: .token, value: true),
            ULongAttribute(type: .certType, value: CKC_X_509)
        ]

        if let id {
            certTemplate.append(BufferAttribute(type: .id, value: Array(id.utf8)))
        }

        let certObjects = try Token.findObjects(certTemplate.map { $0.attribute }, in: session.handle)

        for obj in certObjects {
            certs.append(Pkcs11Object(with: obj, session))
        }
        return certs
    }

    func enumerateKeys(by id: String?, with type: KeyAlgorithm?) throws -> [Pkcs11KeyPair] {
        var keyPairs: [Pkcs11KeyPair] = []

        // MARK: Prepare key templates
        var pubKeyTemplate: [PkcsAttribute] = [
            ULongAttribute(type: .classObject, value: CKO_PUBLIC_KEY),
            BoolAttribute(type: .token, value: true),
            BoolAttribute(type: .privateness, value: false)
        ]
        var privateKeyTemplate: [PkcsAttribute] = [
            ULongAttribute(type: .classObject, value: CKO_PRIVATE_KEY),
            BoolAttribute(type: .token, value: true),
            BoolAttribute(type: .privateness, value: true)
        ]

        switch type {
        case .gostR3410_2012_256:
            pubKeyTemplate.append(ULongAttribute(type: .keyType, value: CKK_GOSTR3410))
            privateKeyTemplate.append(ULongAttribute(type: .keyType, value: CKK_GOSTR3410))
        case .none: break
        }

        if let id {
            pubKeyTemplate.append(BufferAttribute(type: .id, value: Array(id.utf8)))
            privateKeyTemplate.append(BufferAttribute(type: .id, value: Array(id.utf8)))
        }

        // MARK: Find public keys
        let pubKeyObjects = try Token.findObjects(pubKeyTemplate.map { $0.attribute }, in: session.handle)

        var publicKeys: [Pkcs11Object] = []
        for obj in pubKeyObjects {
            publicKeys.append(Pkcs11Object(with: obj, session))
        }

        // MARK: Find private keys
        let privateKeyObjects = try Token.findObjects(privateKeyTemplate.map { $0.attribute }, in: session.handle)

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

        guard let wrappedKey = WrappedPointer<OpaquePointer>({
            try? engine.wrapKeys(with: session.handle,
                                 privateKeyHandle: keyPair.privateKey.handle,
                                 pubKeyHandle: keyPair.pubKey.handle)
        }, EVP_PKEY_free) else {
            throw TokenError.generalError
        }
        return wrappedKey
    }

    func generateKeyPair(with id: String) throws {
        var publicKey = CK_OBJECT_HANDLE()
        var privateKey = CK_OBJECT_HANDLE()

        let currentDate = Date()

        let publicKeyAttributes: [PkcsAttribute] = [
            ULongAttribute(type: .classObject, value: CKO_PUBLIC_KEY),
            BufferAttribute(type: .id, value: Array(id.utf8)),
            ULongAttribute(type: .keyType, value: CKK_GOSTR3410),
            BoolAttribute(type: .token, value: true),
            BoolAttribute(type: .privateness, value: false),
            ObjectAttribute(type: .startDate(currentDate)),
            ObjectAttribute(type: .endDate(currentDate.addingTimeInterval(3 * 365 * 24 * 60 * 60))),
            BufferAttribute(type: .gostR3410Params, value: PkcsConstants.parametersGostR3410_2012_256),
            BufferAttribute(type: .gostR3411Params, value: PkcsConstants.parametersGostR3411_2012_256)
        ]

        let privateKeyAttributes: [PkcsAttribute] = [
            ULongAttribute(type: .classObject, value: CKO_PRIVATE_KEY),
            BufferAttribute(type: .id, value: Array(id.utf8)),
            ULongAttribute(type: .keyType, value: CKK_GOSTR3410),
            BoolAttribute(type: .token, value: true),
            BoolAttribute(type: .privateness, value: true),
            BoolAttribute(type: .derive, value: true),
            ObjectAttribute(type: .startDate(currentDate)),
            ObjectAttribute(type: .endDate(currentDate.addingTimeInterval(3 * 365 * 24 * 60 * 60))),
            BufferAttribute(type: .gostR3410Params, value: PkcsConstants.parametersGostR3410_2012_256),
            BufferAttribute(type: .gostR3411Params, value: PkcsConstants.parametersGostR3411_2012_256)
        ]
        var publicKeyTemplate = publicKeyAttributes.map { $0.attribute }
        var privateKeyTemplate = privateKeyAttributes.map { $0.attribute }

        var gostR3410_2012_256KeyPairGenMech: CK_MECHANISM = CK_MECHANISM(mechanism: CKM_GOSTR3410_KEY_PAIR_GEN, pParameter: nil, ulParameterLen: 0)

        let rv = C_GenerateKeyPair(session.handle, &gostR3410_2012_256KeyPairGenMech,
                                   &publicKeyTemplate, CK_ULONG(publicKeyTemplate.count),
                                   &privateKeyTemplate, CK_ULONG(privateKeyTemplate.count),
                                   &publicKey, &privateKey)
        guard rv == CKR_OK else {
            throw rv == CKR_DEVICE_REMOVED ? TokenError.tokenDisconnected: TokenError.generalError
        }
    }

    func deleteObjects(with id: String) throws {
        let template: [PkcsAttribute] = [
            BufferAttribute(type: .id, value: Array(id.utf8))
        ]

        let objects = try Token.findObjects(template.map { $0.attribute }, in: session.handle)

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
        let certAttributes: [PkcsAttribute] = [
            BufferAttribute(type: .value, value: [UInt8](cert)),
            ULongAttribute(type: .classObject, value: CKO_CERTIFICATE),
            BufferAttribute(type: .id, value: Array(id.utf8)),
            BoolAttribute(type: .token, value: true),
            BoolAttribute(type: .privateness, value: false),
            ULongAttribute(type: .certType, value: CKC_X_509),
            ULongAttribute(type: .certCategory, value: PkcsConstants.CK_CERTIFICATE_CATEGORY_TOKEN_USER)
        ]
        var certTemplate = certAttributes.map { $0.attribute }

        var certHandle = CK_OBJECT_HANDLE()
        let rv = C_CreateObject(session.handle, &certTemplate, CK_ULONG(certTemplate.count), &certHandle)
        guard rv == CKR_OK else {
            throw rv == CKR_DEVICE_REMOVED ? TokenError.tokenDisconnected: TokenError.generalError
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
        let objectAttributes = [
            ULongAttribute(type: .classObject, value: CKO_HW_FEATURE),
            ULongAttribute(type: .hwFeatureType, value: CKH_VENDOR_TOKEN_INFO)
        ]
        let attributes = [
            BufferAttribute(type: .vendorCurrentInterface),
            BufferAttribute(type: .vendorSupportedInterface)
        ]

        guard let template = readAttributes(objectAttributes: objectAttributes, attributes: attributes, in: session) else {
            return nil
        }
        defer {
            template.forEach {
                $0.pValue.deallocate()
            }
        }
        return (UnsafeRawBufferPointer(start: template[0].pValue.assumingMemoryBound(to: UInt8.self),
                                       count: Int(template[0].ulValueLen)).load(as: CK_ULONG.self),
                UnsafeRawBufferPointer(start: template[1].pValue.assumingMemoryBound(to: UInt8.self),
                                       count: Int(template[1].ulValueLen)).load(as: CK_ULONG.self))
    }

    class private func getTokenVendorModel(session: CK_SESSION_HANDLE) -> String? {
        let objectAttributes = [
            ULongAttribute(type: .classObject, value: CKO_HW_FEATURE),
            ULongAttribute(type: .hwFeatureType, value: CKH_VENDOR_TOKEN_INFO)
        ]
        let attribute = BufferAttribute(type: .vendorModelName)

        guard let template = readAttributes(objectAttributes: objectAttributes, attributes: [attribute], in: session) else {
            return nil
        }
        defer {
            template.forEach {
                $0.pValue.deallocate()
            }
        }
        guard let stringPtr = UnsafeRawBufferPointer(start: template[0].pValue.assumingMemoryBound(to: UInt8.self),
                                                     count: Int(template[0].ulValueLen)).assumingMemoryBound(to: CChar.self).baseAddress else {
            return nil
        }
        return String(cString: stringPtr)
    }

    class private func readAttributes(objectAttributes: [PkcsAttribute],
                                      attributes: [PkcsAttribute], in session: CK_SESSION_HANDLE) -> [CK_ATTRIBUTE]? {
        guard let handle = try? Token.findObjects(objectAttributes.map { $0.attribute }, in: session).first else {
            return nil
        }
        var template = attributes.map { $0.attribute }
        var rv = C_GetAttributeValue(session, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            return nil
        }

        for i in 0..<template.count {
            template[i].pValue = UnsafeMutableRawPointer.allocate(byteCount: Int(template[i].ulValueLen), alignment: 1)
        }

        rv = C_GetAttributeValue(session, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            return nil
        }

        return template
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
