//
//  Pkcs11Token.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//

import Foundation

import RtMock


@RtMock
protocol Pkcs11TokenProtocol {
    var slot: CK_SLOT_ID { get }
    var label: String? { get }
    var serial: String { get }
    var model: Pkcs11TokenModel { get }

    var currentInterface: Pkcs11TokenInterface { get }
    var supportedInterfaces: Set<Pkcs11TokenInterface> { get }

    func login(with pin: String) throws
    func logout()

    func generateKeyPair(with id: String) throws

    func enumerateCerts() throws -> [Pkcs11ObjectProtocol]
    func enumerateCerts(by id: String) throws -> [Pkcs11ObjectProtocol]

    func enumerateKeys(by algo: Pkcs11KeyAlgorithm) throws -> [Pkcs11KeyPair]
    func enumerateKey(by id: String) throws -> Pkcs11KeyPair

    func getWrappedKey(with id: String) throws -> WrappedPointer<OpaquePointer>

    func importCert(_ cert: Data, for id: String) throws

    func deleteCert(with id: String) throws

    func getPinAttempts() throws -> UInt
}

class Pkcs11Token: Pkcs11TokenProtocol, Identifiable {
    let slot: CK_SLOT_ID
    private let session: Pkcs11Session
    private let engine: RtEngineWrapperProtocol
    private var tokenInfo: CK_TOKEN_INFO
    private var extendedTokenInfo: CK_TOKEN_INFO_EXTENDED

    var label: String?
    var serial: String = ""
    var model: Pkcs11TokenModel = .rutoken2_2000
    var currentInterface: Pkcs11TokenInterface = .usb
    var supportedInterfaces: Set<Pkcs11TokenInterface> = .init()

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
        try session.login(pin: pin)
    }

    func logout() {
        session.logout()
    }

    func enumerateCerts() throws -> [Pkcs11ObjectProtocol] {
        try Pkcs11Template.makeCertBaseTemplate().withCkTemplate {
            try session.findObjects($0)
        }
    }

    func enumerateCerts(by id: String) throws -> [Pkcs11ObjectProtocol] {
        try Pkcs11Template.makeCertBaseTemplate()
            .add(attr: .id, value: Data(id.utf8))
            .withCkTemplate {
            try session.findObjects($0)
        }
    }

    func enumerateKeys(by algo: Pkcs11KeyAlgorithm) throws -> [Pkcs11KeyPair] {
        // MARK: Find public keys
        let publicKeys = try Pkcs11Template.makePubKeyBaseTemplate()
            .add(attr: .keyType, value: algo.rawValue)
            .withCkTemplate {
                 try session.findObjects($0)
            }

        // MARK: Find private keys
        let privateKeys = try Pkcs11Template.makePrivKeyBaseTemplate()
            .add(attr: .keyType, value: algo.rawValue)
            .withCkTemplate {
                 try session.findObjects($0)
            }

        return try privateKeys.compactMap { privateKey in
            guard let publicKey = try publicKeys.first(where: { try $0.getValue(forAttr: .id) == privateKey.getValue(forAttr: .id) }) else {
                return nil
            }
            return Pkcs11KeyPair(publicKey: publicKey, privateKey: privateKey)
        }
    }

    func enumerateKey(by id: String) throws -> Pkcs11KeyPair {
        // MARK: Find public keys
        let publicKeys = try Pkcs11Template.makePubKeyBaseTemplate()
            .add(attr: .id, value: Data(id.utf8))
            .withCkTemplate {
                 try session.findObjects($0)
            }

        // MARK: Find private keys
        let privateKeys = try Pkcs11Template.makePrivKeyBaseTemplate()
            .add(attr: .id, value: Data(id.utf8))
            .withCkTemplate {
                 try session.findObjects($0)
            }

        // MARK: There should be only one key of each type with same id
        guard publicKeys.count == 1,
              privateKeys.count == 1 else {
            throw Pkcs11Error.internalError()
        }

        return Pkcs11KeyPair(publicKey: publicKeys[0], privateKey: privateKeys[0])
    }

    func getWrappedKey(with id: String) throws -> WrappedPointer<OpaquePointer> {
        let keyPair = try enumerateKey(by: id)

        guard let wrappedKey = WrappedPointer<OpaquePointer>({
            try? engine.wrapKeys(with: session.handle,
                                 privateKeyHandle: keyPair.privateKey.handle,
                                 pubKeyHandle: keyPair.publicKey.handle)
        }, EVP_PKEY_free) else {
            throw Pkcs11Error.internalError()
        }
        return wrappedKey
    }

    func generateKeyPair(with id: String) throws {
        var publicKey = CK_OBJECT_HANDLE()
        var privateKey = CK_OBJECT_HANDLE()

        let currentDate = Date()
        var startDateData = Pkcs11Date(date: currentDate)
        var endDateData = Pkcs11Date(date: currentDate.addingTimeInterval(3 * 365 * 24 * 60 * 60))
        let idData = Data(id.utf8)

        let publicKeyTemplate = Pkcs11Template.makePubKeyBaseTemplate()
            .add(attr: .id, value: idData)
            .add(attr: .keyType, value: CKK_GOSTR3410)
            .add(attr: .startDate, value: startDateData.data())
            .add(attr: .endDate, value: endDateData.data())
            .add(attr: .gostR3410Params, value: Data(Pkcs11Constants.gostR3410_2012_256_paramset_B))
            .add(attr: .gostR3411Params, value: Data(Pkcs11Constants.gostR3411_2012_256_params_oid))

        let privateKeyTemplate = Pkcs11Template.makePrivKeyBaseTemplate()
            .add(attr: .id, value: idData)
            .add(attr: .keyType, value: CKK_GOSTR3410)
            .add(attr: .derive, value: true)
            .add(attr: .startDate, value: startDateData.data())
            .add(attr: .endDate, value: endDateData.data())
            .add(attr: .gostR3410Params, value: Data(Pkcs11Constants.gostR3410_2012_256_paramset_B))
            .add(attr: .gostR3411Params, value: Data(Pkcs11Constants.gostR3411_2012_256_params_oid))

        var gostR3410_2012_256KeyPairGenMech: CK_MECHANISM = CK_MECHANISM(mechanism: CKM_GOSTR3410_KEY_PAIR_GEN, pParameter: nil, ulParameterLen: 0)

        try publicKeyTemplate.withCkTemplate { pubCkTemplate in
            try privateKeyTemplate.withCkTemplate { prvCkTemplate in
                let rv = C_GenerateKeyPair(session.handle, &gostR3410_2012_256KeyPairGenMech,
                                           &pubCkTemplate, CK_ULONG(pubCkTemplate.count),
                                           &prvCkTemplate, CK_ULONG(prvCkTemplate.count),
                                           &publicKey, &privateKey)
                guard rv == CKR_OK else {
                    throw Pkcs11Error.internalError(rv: rv)
                }
            }
        }

    }

    func deleteCert(with id: String) throws {
        try Pkcs11Template.makeCertBaseTemplate()
            .add(attr: .id, value: Data(id.utf8))
            .withCkTemplate {
                try deleteObjects(with: $0)
            }
    }

    func importCert(_ cert: Data, for id: String) throws {
        _ = try enumerateKey(by: id)

        try Pkcs11Template.makeCertBaseTemplate()
            .add(attr: .id, value: Data(id.utf8))
            .add(attr: .value, value: cert)
            .add(attr: .privateness, value: false)
            .add(attr: .certCategory, value: Pkcs11Constants.CK_CERTIFICATE_CATEGORY_TOKEN_USER)
            .withCkTemplate {
                var certHandle = CK_OBJECT_HANDLE()
                let rv = C_CreateObject(session.handle, &$0, CK_ULONG($0.count), &certHandle)
                guard rv == CKR_OK else {
                    throw Pkcs11Error.internalError(rv: rv)
                }
            }
    }

    func getPinAttempts() throws -> UInt {
        var exInfo = CK_TOKEN_INFO_EXTENDED()
        exInfo.ulSizeofThisStructure = UInt(MemoryLayout.size(ofValue: exInfo))
        let rv = C_EX_GetTokenInfoExtended(slot, &exInfo)
        guard rv == CKR_OK else {
            throw Pkcs11Error.internalError(rv: rv)
        }

        return exInfo.ulUserRetryCountLeft
    }

    // MARK: - Private API

    private func getTokenInterfaces() throws -> (Pkcs11TokenInterface, Set<Pkcs11TokenInterface>) {
        guard let hwFeature = try? Pkcs11Template()
            .add(attr: .classObject, value: CKO_HW_FEATURE)
            .add(attr: .hwFeatureType, value: CKH_VENDOR_TOKEN_INFO)
            .withCkTemplate({
                try session.findObjects($0).first
            }) else {
            throw Pkcs11Error.internalError()
        }

        let currentInterfaceBits = try hwFeature.getValue(forAttr: .vendorCurrentInterface)
        let supportedInterfacesBits = try hwFeature.getValue(forAttr: .vendorSupportedInterface)

        guard let currentInterface = Pkcs11TokenInterface(currentInterfaceBits.withUnsafeBytes { rawBuffer in
            rawBuffer.load(as: CK_ULONG.self)
        }) else {
            throw Pkcs11Error.internalError()
        }
        return (currentInterface, Set([Pkcs11TokenInterface](bits: supportedInterfacesBits.withUnsafeBytes { rawBuffer in
            rawBuffer.load(as: CK_ULONG.self)
        })))
    }

    private func initTokenInfo() throws {
        // MARK: Get serial number
        guard let hexSerial = String.getFrom(tokenInfo.serialNumber),
              let decimalSerial = Int(hexSerial.trimmingCharacters(in: .whitespacesAndNewlines), radix: 16) else {
            throw Pkcs11Error.internalError()
        }
        serial = String(format: "%0.10d", decimalSerial)

        // MARK: Get label
        guard let label = String.getFrom(tokenInfo.label)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw Pkcs11Error.internalError()
        }
        if !label.hasSuffix(("<no label>")), !label.hasSuffix(("<corrupted label!>")) {
            self.label = label
        }

        // MARK: Get token model
        if tokenInfo.firmwareVersion.major >= 32 {
            let modelName = try getTokenModelFromToken()
            model = .rutokenSelfIdentify(modelName)
        } else {
            guard let model = computeTokenModel() else {
                throw Pkcs11Error.internalError()
            }
            self.model = model
        }
    }

    private func deleteObjects(with attrs: [CK_ATTRIBUTE]) throws {
        let objects = try session.findObjects(attrs)

        for obj in objects {
            let rv = C_DestroyObject(session.handle, obj.handle)
            guard rv == CKR_OK else {
                throw Pkcs11Error.internalError(rv: rv)
            }
        }
    }

    private func computeTokenModel() -> Pkcs11TokenModel? {
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
            return .rutoken3_3220
        case (60, _, 30, _, false, false),
            (60, _, 28, _, false, false):
            if supportedInterfaces.contains(.nfc) {
                return .rutoken3Nfc_3100
            } else {
                return .rutoken3_3100
            }
        case (60, _, 31, _, false, false):
            return .rutoken3NfcMf_3110
        case (_, _, 30, _, false, false):
            return .rutoken3Ble_8100
        case (_, _, 24, _, false, false):
            return .rutoken2_2010
        default:
            return nil
        }
    }

    private func getTokenModelFromToken() throws -> String {
        guard let object = try? Pkcs11Template()
            .add(attr: .classObject, value: CKO_HW_FEATURE)
            .add(attr: .hwFeatureType, value: CKH_VENDOR_TOKEN_INFO)
            .withCkTemplate({
                try session.findObjects($0).first
            }),
              let result = try String(data: object.getValue(forAttr: .vendorModelName), encoding: .utf8) else {
            throw Pkcs11Error.internalError()
        }
        return result
    }
}
