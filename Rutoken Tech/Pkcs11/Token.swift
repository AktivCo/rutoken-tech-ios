//
//  Token.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//


protocol TokenProtocol {
    var slot: CK_SLOT_ID { get }
    var label: String { get }
    var serial: String { get }
    var model: TokenModel { get }
    var type: TokenType { get }
    var connectionType: ConnectionType { get }

    func login(with pin: String) throws
    func generateKeyPair(with id: String) throws
    func deleteKeyPair(with id: String) throws
}

enum TokenError: Error {
    case incorrectPin(attemptsLeft: UInt)
    case lockedPin
    case generalError
    case tokenDisconnected
}

class Token: TokenProtocol, Identifiable {
    let slot: CK_SLOT_ID

    let label: String
    let serial: String
    private(set) var model: TokenModel = .rutoken2
    private(set) var connectionType: ConnectionType = .nfc
    private(set) var type: TokenType = .usb

    private var session = CK_SESSION_HANDLE(NULL_PTR)

    init?(with slot: CK_SLOT_ID) {
        self.slot = slot

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
        var extendedTokenInfo = CK_TOKEN_INFO_EXTENDED()
        extendedTokenInfo.ulSizeofThisStructure = UInt(MemoryLayout.size(ofValue: extendedTokenInfo))
        rv = C_EX_GetTokenInfoExtended(slot, &extendedTokenInfo)
        guard rv == CKR_OK else {
            return nil
        }

        rv = C_OpenSession(self.slot, CK_FLAGS(CKF_SERIAL_SESSION | CKF_RW_SESSION), nil, nil, &self.session)
        guard rv == CKR_OK else {
            return nil
        }
        guard let (currentInterfaceBits, supportedInterfacesBits) = getTokenInterfaces() else {
            return nil
        }

        guard let interface = TokenInterface(currentInterfaceBits) else {
            return nil
        }
        let supportedInterfaces = Set([TokenInterface](bits: supportedInterfacesBits))

        switch interface {
        case .nfc:
            type = supportedInterfaces.contains(.usb) ? .dual : .sc
            connectionType = .nfc
        case .sc:
            type = .sc
            connectionType = .usb
        case .usb:
            type = supportedInterfaces.contains(.nfc) ? .dual : .usb
            connectionType = .usb
        }

        guard let model = TokenModel(tokenInfo.hardwareVersion, tokenInfo.firmwareVersion,
                                     extendedTokenInfo.ulTokenClass, type: self.type) else {
            return nil
        }
        self.model = model
    }

    // MARK: - Public API
    func login(with pin: String) throws {
        try checkingToken {
            var rawPin: [UInt8] = Array(pin.utf8)
            let rv = C_Login(session, CK_USER_TYPE(CKU_USER), &rawPin, CK_ULONG(rawPin.count))
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
    }

    func logout() {
        C_Logout(session)
    }

    func generateKeyPair(with id: String) throws {
        var publicKey = CK_OBJECT_HANDLE()
        var privateKey = CK_OBJECT_HANDLE()

        var publicKeyTemplate = getPublicKeyTemplate(with: id)
        var privateKeyTemplate = getPrivateKeyTemplate(with: id)

        var gostR3410_2012_256KeyPairGenMech: CK_MECHANISM = CK_MECHANISM(mechanism: CKM_GOSTR3410_KEY_PAIR_GEN, pParameter: nil, ulParameterLen: 0)

        let rv = C_GenerateKeyPair(session, &gostR3410_2012_256KeyPairGenMech,
                                   &publicKeyTemplate, CK_ULONG(publicKeyTemplate.count),
                                   &privateKeyTemplate, CK_ULONG(privateKeyTemplate.count),
                                   &publicKey, &privateKey)
        guard rv == CKR_OK else {
            throw rv == CKR_DEVICE_REMOVED ? TokenError.tokenDisconnected: TokenError.generalError
        }
    }

    func deleteKeyPair(with id: String) throws {
        let template = [
            id.withCString {
                AttributeType.ckaId(UnsafeMutableRawPointer(mutating: $0), UInt(id.count))
            },
            AttributeType.keyType
        ].map { $0.attr }

        guard let objects = try? findObjects(template) else {
            throw TokenError.generalError
        }

        guard !objects.isEmpty else {
            throw TokenError.generalError
        }

        for obj in objects {
            let rv = C_DestroyObject(session, obj)
            guard rv == CKR_OK else {
                throw TokenError.generalError
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

    private func getPinAttempts() throws -> UInt {
        var exInfo = CK_TOKEN_INFO_EXTENDED()
        exInfo.ulSizeofThisStructure = UInt(MemoryLayout.size(ofValue: exInfo))
        let rv = C_EX_GetTokenInfoExtended(slot, &exInfo)
        guard rv == CKR_OK else {
            throw TokenError.generalError
        }

        return exInfo.ulUserRetryCountLeft
    }

    private func getTokenInterfaces() -> (CK_ULONG, CK_ULONG)? {
        let objectTemplate = [AttributeType.ckaClass(.hwFeature), AttributeType.hwFeatureType].map { $0.attr }

        guard let handle = try? findObjects(objectTemplate).first else {
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

    private func findObjects(_ attributes: [CK_ATTRIBUTE]) throws -> [CK_OBJECT_HANDLE] {
        var template = attributes
        var rv = C_FindObjectsInit(session, &template, CK_ULONG(template.count))
        guard rv == CKR_OK else {
            throw TokenError.generalError
        }
        defer {
            C_FindObjectsFinal(self.session)
        }

        var count: CK_ULONG = 0
        // You can define your own number of required objects.
        let maxCount: CK_ULONG = 16
        var objects: [CK_OBJECT_HANDLE] = []
        repeat {
            var handles: [CK_OBJECT_HANDLE] = Array(repeating: 0x00, count: Int(maxCount))

            rv = C_FindObjects(self.session, &handles, maxCount, &count)
            guard rv == CKR_OK else {
                throw TokenError.generalError
            }

            objects += handles.prefix(Int(count))
        } while count == maxCount

        return objects
    }
}

extension Token {
    func getPublicKeyTemplate(with id: String) -> [CK_ATTRIBUTE] {
        var template: [AttributeType] = [.ckaClass(.publicKey), .keyType,
                                         .attrTrue(CKA_TOKEN), .attrFalse(CKA_PRIVATE),
                                         .gostR3410_2012_256_params, .gostR3411_2012_256_params]
        id.withCString {
            template.append(.ckaId(UnsafeMutableRawPointer(mutating: $0), UInt(id.count)))
        }
        return template.map {
            $0.attr
        }
    }

    func getPrivateKeyTemplate(with id: String) -> [CK_ATTRIBUTE] {
        var template: [AttributeType] = [.ckaClass(.privateKey), .keyType,
                                         .attrTrue(CKA_TOKEN), .attrTrue(CKA_PRIVATE), .attrTrue(CKA_DERIVE),
                                         .gostR3410_2012_256_params, .gostR3411_2012_256_params]
        id.withCString {
            template.append(.ckaId(UnsafeMutableRawPointer(mutating: $0), UInt(id.count)))
        }
        return template.map {
            $0.attr
        }
    }
}
