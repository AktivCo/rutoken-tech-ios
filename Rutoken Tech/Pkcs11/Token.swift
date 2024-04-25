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
    private var tokenInfo: CK_TOKEN_INFO
    private var extendedTokenInfo: CK_TOKEN_INFO_EXTENDED

    var label: String = ""
    var serial: String = ""
    var model: TokenModel = .rutoken2_2000
    var currentInterface: TokenInterface = .usb
    var supportedInterfaces: Set<TokenInterface> = .init()

    init?(with slot: CK_SLOT_ID, _ engine: RtEngineWrapperProtocol) {
        self.slot = slot
        self.engine = engine

        // MARK: Get tokenInfo and tokenExtendedInfo
        var tokenInfo = CK_TOKEN_INFO()
        var rv = C_GetTokenInfo(slot, &tokenInfo)
        guard rv == CKR_OK else {
            return nil
        }
        self.tokenInfo = tokenInfo

        var extendedTokenInfo = CK_TOKEN_INFO_EXTENDED()
        extendedTokenInfo.ulSizeofThisStructure = UInt(MemoryLayout.size(ofValue: extendedTokenInfo))
        rv = C_EX_GetTokenInfoExtended(slot, &extendedTokenInfo)
        guard rv == CKR_OK else {
            return nil
        }
        self.extendedTokenInfo = extendedTokenInfo

        // MARK: Get PkcsSession
        guard let session = Pkcs11Session(slot: self.slot) else {
            return nil
        }
        self.session = session

        do {
            let (currentInterface, supportedInterfaces) = try getTokenInterfaces()
            self.currentInterface = currentInterface
            self.supportedInterfaces = supportedInterfaces
            try initTokenInfo()
        } catch {
            return nil
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

        let certObjects = try findObjects(certTemplate.map { $0.attribute })

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
        let pubKeyObjects = try findObjects(pubKeyTemplate.map { $0.attribute })

        var publicKeys: [Pkcs11Object] = []
        for obj in pubKeyObjects {
            publicKeys.append(Pkcs11Object(with: obj, session))
        }

        // MARK: Find private keys
        let privateKeyObjects = try findObjects(privateKeyTemplate.map { $0.attribute })

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

        let objects = try findObjects(template.map { $0.attribute })

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

    private func getTokenInterfaces() throws -> (TokenInterface, Set<TokenInterface>) {
        let objectAttributes = [
            ULongAttribute(type: .classObject, value: CKO_HW_FEATURE),
            ULongAttribute(type: .hwFeatureType, value: CKH_VENDOR_TOKEN_INFO)
        ]
        let attributes = [
            BufferAttribute(type: .vendorCurrentInterface),
            BufferAttribute(type: .vendorSupportedInterface)
        ]

        guard let handle = try? findObjects(objectAttributes.map { $0.attribute }).first else {
            throw TokenError.generalError
        }
        guard let wrappedTemplate = readAttributes(handle: handle, attributes: attributes) else {
            throw TokenError.generalError
        }
        let template = wrappedTemplate.value

        let currentInterfaceBits = UnsafeRawBufferPointer(start: template[0].pValue.assumingMemoryBound(to: UInt8.self),
                                                          count: Int(template[0].ulValueLen)).load(as: CK_ULONG.self)
        let supportedInterfacesBits = UnsafeRawBufferPointer(start: template[1].pValue.assumingMemoryBound(to: UInt8.self),
                                                             count: Int(template[1].ulValueLen)).load(as: CK_ULONG.self)

        guard let currentInterface = TokenInterface(currentInterfaceBits) else {
            throw TokenError.generalError
        }
        return (currentInterface, Set([TokenInterface](bits: supportedInterfacesBits)))
    }

    private func initTokenInfo() throws {
        // MARK: Get serial number
        guard let hexSerial = String.getFrom(tokenInfo.serialNumber),
              let decimalSerial = Int(hexSerial.trimmingCharacters(in: .whitespacesAndNewlines), radix: 16) else {
            throw TokenError.generalError
        }
        serial = String(format: "%0.10d", decimalSerial)

        // MARK: Get label
        guard let label = String.getFrom(tokenInfo.label)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw TokenError.generalError
        }
        self.label = label

        // MARK: Get token model
        if tokenInfo.firmwareVersion.major >= 32 {
            guard let modelName = getTokenModelFromToken() else {
                throw TokenError.generalError
            }
            model = .rutokenSelfIdentify(modelName)
        } else {
            guard let model = computeTokenModel() else {
                throw TokenError.generalError
            }
            self.model = model
        }
    }

    private func computeTokenModel() -> TokenModel? {
        let AA = tokenInfo.hardwareVersion.major
        let BB = tokenInfo.hardwareVersion.minor
        let CC = tokenInfo.firmwareVersion.major
        let DD = tokenInfo.firmwareVersion.minor
        let containsFlashDrive = extendedTokenInfo.flags & TOKEN_FLAGS_HAS_FLASH_DRIVE == 0 ? false : true
        let containsTouchButton = extendedTokenInfo.flags & TOKEN_FLAGS_HAS_BUTTON == 0 ? false : true

        switch (AA, BB, CC, DD, containsFlashDrive, containsTouchButton) {
        case (20, _, 23, _, false, false),
            (59, _, 26, _, false, false):
            return .rutoken2_2000
        case (54, _, 23, 2, false, false):
            return .rutoken2_2100
        case (20, _, 24, _, false, false):
            return .rutoken2_2200
        case (20, _, 26, _, false, false),
            (59, _, 27, _, false, false):
            return .rutoken2_3000
        case (55, _, 24, _, false, false):
            return .rutoken2_4000
        case (55, _, 24, _, false, true):
            return .rutoken2_4400
        case (55, _, 24, _, true, false),
            (59, _, 26, _, true, false),
            (55, _, 27, _, true, false),
            (58...59, _, 27, _, true, false):
            return .rutoken2_4500
        case (55, _, 24, _, true, true),
            (55, _, 27, _, true, true),
            (59, _, 27, _, true, true):
            return .rutoken2_4900
        case (_, _, 21, _, false, false),
            (_, _, 25, _, false, false):
            return .rutoken2_8003
        case (59, _, 30, _, false, false):
            return .rutoken3_3200
        case (65, _, 30, _, false, false):
            return  .rutoken3_3220
        case (60, _, 30, _, false, false),
            (60, _, 28, _, false, false):
            if supportedInterfaces.contains(.nfc) {
                return .rutoken3Nfc_3100
            } else {
                return  .rutoken3_3100
            }
        case (60, _, 31, _, false, false):
            return  .rutoken3NfcMf_3110
        case (_, _, 30, _, false, false):
            return .rutoken3Ble_8100
        case (_, _, 24, _, false, false):
            return .rutoken2_2010
        default:
            return nil
        }
    }

    private func getTokenModelFromToken() -> String? {
        let objectAttributes = [
            ULongAttribute(type: .classObject, value: CKO_HW_FEATURE),
            ULongAttribute(type: .hwFeatureType, value: CKH_VENDOR_TOKEN_INFO)
        ]
        let attribute = BufferAttribute(type: .vendorModelName)

        guard let handle = try? findObjects(objectAttributes.map { $0.attribute }).first else {
            return nil
        }
        guard let wrappedTemplate = readAttributes(handle: handle, attributes: [attribute]) else {
            return nil
        }
        let template = wrappedTemplate.value

        guard let stringPtr = UnsafeRawBufferPointer(start: template[0].pValue.assumingMemoryBound(to: UInt8.self),
                                                     count: Int(template[0].ulValueLen)).assumingMemoryBound(to: CChar.self).baseAddress else {
            return nil
        }
        return String(cString: stringPtr)
    }

    private func readAttributes(handle: CK_OBJECT_HANDLE,
                                attributes: [PkcsAttribute]) -> WrappedValue<[CK_ATTRIBUTE]>? {
        var template = attributes.map { $0.attribute }
        var rv = C_GetAttributeValue(session.handle, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            return nil
        }

        for i in 0..<template.count {
            template[i].pValue = UnsafeMutableRawPointer.allocate(byteCount: Int(template[i].ulValueLen), alignment: 1)
        }

        rv = C_GetAttributeValue(session.handle, handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            return nil
        }

        let result = WrappedValue(template, { $0.forEach { attrib in
            attrib.pValue.deallocate()
        }})
        return result
    }

    private func findObjects(_ attributes: [CK_ATTRIBUTE]) throws -> [CK_OBJECT_HANDLE] {
        var template = attributes
        var rv = C_FindObjectsInit(session.handle, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw rv == CKR_DEVICE_REMOVED ? TokenError.tokenDisconnected: TokenError.generalError
        }
        defer {
            C_FindObjectsFinal(session.handle)
        }

        var count: CK_ULONG = 0
        // You can define your own number of required objects.
        let maxCount: CK_ULONG = 16
        var objects: [CK_OBJECT_HANDLE] = []
        repeat {
            var handles: [CK_OBJECT_HANDLE] = Array(repeating: 0x00, count: Int(maxCount))

            rv = C_FindObjects(session.handle, &handles, maxCount, &count)
            guard rv == CKR_OK else {
                throw rv == CKR_DEVICE_REMOVED ? TokenError.tokenDisconnected: TokenError.generalError
            }

            objects += handles.prefix(Int(count))
        } while count == maxCount

        return objects
    }
}
