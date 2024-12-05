//
//  OpenSslHelper.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 15.01.2024.
//

import Foundation

import RtMock


enum OpenSslError: Error, Equatable {
    case generalError(UInt32, String?)
}

@RtMock
protocol OpenSslHelperProtocol {
    func createCsr(with wrappedKey: WrappedPointer<OpaquePointer>, for request: CsrModel, with info: CertInfo) throws -> String
    func createCert(for csr: String, with caKey: Data, cert caCert: Data) throws -> Data
    func signDocument(_ document: Data, wrappedKey: WrappedPointer<OpaquePointer>, cert: Data, certChain: [Data]) throws -> String
    func signDocument(_ document: Data, key: Data, cert: Data, certChain: [Data]) throws -> String
    func verifyCms(signedCms: String, for content: Data, trustedRoots: [Data]) throws -> VerifyCmsResult
    func encryptDocument(for content: Data, with cert: Data) throws -> Data
    func decryptCms(content: Data, wrappedKey: WrappedPointer<OpaquePointer>) throws -> Data
}

enum VerifyCmsResult {
    case success
    case failedChain
    case invalidSignature(OpenSslError)
}

class OpenSslHelper: OpenSslHelperProtocol {
    private let requestExtensionsSection = "req_extensions"
    private let requestAttributesSection = "req_attributes"

    init() {
        let r = OPENSSL_init_crypto(UInt64(OPENSSL_INIT_NO_LOAD_CONFIG | OPENSSL_INIT_NO_ATEXIT), nil)
        assert(r == 1)
    }

    deinit {
        OPENSSL_cleanup()
    }

    func signDocument(_ document: Data, wrappedKey: WrappedPointer<OpaquePointer>, cert: Data, certChain: [Data]) throws -> String {
        guard let contentBio = dataToBio(document) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { contentBio.release() }

        guard let x509 = WrappedX509(from: cert) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        let certsStack = createX509Stack(with: certChain)
        guard certChain.isEmpty || certsStack != nil else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { withExtendedLifetime(x509) {} }
        defer { certsStack?.release() }

        guard let cms = WrappedPointer<OpaquePointer>({
            CMS_sign(x509.wrappedPointer.pointer, wrappedKey.pointer, certsStack?.pointer,
                     contentBio.pointer, UInt32(CMS_BINARY | CMS_NOSMIMECAP | CMS_DETACHED))
        }, CMS_ContentInfo_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { cms.release() }

        let cmsLength = i2d_CMS_ContentInfo(cms.pointer, nil)
        guard cmsLength >= 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        var cmsData = Data(repeating: 0x00, count: Int(cmsLength))
        try cmsData.withUnsafeMutableBytes {
            var pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
            guard i2d_CMS_ContentInfo(cms.pointer, &pointer) >= 0 else {
                throw OpenSslError.generalError(#line, getLastError())
            }
        }

        // Add EOL after every 64th symbol to improve readability
        // 64 is chosen by sense of beauty
        let rawSignature = cmsData.base64EncodedString().enumerated().map { (idx, el) in
            idx > 0 && idx % 64 == 0 ? ["\n", el] : [el]
        }.joined()

        return "-----BEGIN CMS-----\n" + rawSignature + "\n-----END CMS-----"
    }

    func signDocument(_ document: Data, key: Data, cert: Data, certChain: [Data]) throws -> String {
        guard let privateKey = wrapKey(key) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { privateKey.release() }
        return try self.signDocument(document, wrappedKey: privateKey, cert: cert, certChain: certChain)
    }

    func verifyCms(signedCms: String, for content: Data, trustedRoots: [Data]) throws -> VerifyCmsResult {
        var rawBase64Cms = signedCms
            .replacingOccurrences(of: "-----BEGIN CMS-----", with: "")
            .replacingOccurrences(of: "-----END CMS-----", with: "")

        rawBase64Cms.removeAll { $0 == "\n" }

        guard let contentBio = dataToBio(content) else { throw OpenSslError.generalError(#line, getLastError()) }
        defer { contentBio.release() }

        guard let certStore = WrappedPointer<OpaquePointer>(X509_STORE_new, X509_STORE_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { certStore.release() }

        guard let cms = WrappedPointer<OpaquePointer>({
            let data = Data(rawBase64Cms.utf8)
            guard let cmsData = Data(base64Encoded: data) else {
                return nil
            }

            return cmsData.withUnsafeBytes {
                var pointer: UnsafePointer<UInt8>? = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
                return d2i_CMS_ContentInfo(nil, &pointer, data.count)
            }
        }, CMS_ContentInfo_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { cms.release() }

        for cert in trustedRoots {
            guard let caCert = WrappedX509(from: cert) else {
                throw OpenSslError.generalError(#line, getLastError())
            }
            try withExtendedLifetime(caCert) {
                guard X509_STORE_add_cert(certStore.pointer, caCert.wrappedPointer.pointer) == 1 else {
                    throw OpenSslError.generalError(#line, getLastError())
                }
            }
        }

        guard CMS_verify(cms.pointer,
                         nil,
                         certStore.pointer,
                         contentBio.pointer,
                         nil,
                         UInt32(CMS_BINARY)) == 1 else {
            // If we receive an error on CMS verify we try to verify without chain cheking
            // and send appropriate error
            guard CMS_verify(cms.pointer,
                             nil,
                             certStore.pointer,
                             contentBio.pointer,
                             nil,
                             UInt32(CMS_BINARY | CMS_NO_SIGNER_CERT_VERIFY)) == 1 else {
                return .invalidSignature(OpenSslError.generalError(#line, getLastError()))
            }
            return .failedChain
        }
        return .success
    }

    private func makeConfig(name: String, value: String, isExtension: Bool = true) throws -> WrappedPointer<UnsafeMutablePointer<CONF>> {
        guard let conf = WrappedPointer<UnsafeMutablePointer<CONF>>({ NCONF_new(nil) }, { NCONF_free($0) }) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        let resultString = """
        [\(isExtension ? requestExtensionsSection : requestAttributesSection)]
        \(name)=\(value)
        """

        var eline: Int = 0
        guard let confFileBio = stringToBio(resultString) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { confFileBio.release() }

        guard NCONF_load_bio(conf.pointer, confFileBio.pointer, &eline) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        return conf
    }

    private func addV3Extensions(to stackOfExts: WrappedPointer<OpaquePointer>,
                                 for request: WrappedPointer<OpaquePointer>,
                                 exts: [String: String]) throws {
        for ext in exts {
            let extNid = OBJ_txt2nid(ext.key.cString(using: .utf8))
            let extensionName = extNid == NID_undef ? ext.key : String(cString: OBJ_nid2sn(extNid))
            let value = ext.value

            var extCtx = X509V3_CTX()
            let conf = try makeConfig(name: extensionName, value: value)
            defer { conf.release() }

            X509V3_set_ctx(&extCtx, nil, nil, request.pointer, nil, 0)
            X509V3_set_nconf(&extCtx, conf.pointer)

            var stackPtr: OpaquePointer? = stackOfExts.pointer
            guard X509V3_EXT_add_nconf_sk(conf.pointer, &extCtx, requestExtensionsSection, &stackPtr) != 0 else {
                throw OpenSslError.generalError(#line, getLastError())
            }
        }
    }

    func createCsr(with wrappedKey: WrappedPointer<OpaquePointer>, for request: CsrModel, with info: CertInfo) throws -> String {
        guard let csr = WrappedPointer<OpaquePointer>(X509_REQ_new, X509_REQ_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { csr.release() }

        guard let subject = X509_REQ_get_subject_name(csr.pointer) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Add subjects entry
        for entry in request.subjects {
            guard X509_NAME_add_entry_by_txt(subject,
                                             entry.key.rawValue,
                                             entry.value.allSatisfy(\.isASCII) ? MBSTRING_ASC : MBSTRING_UTF8,
                                             NSString(string: entry.value).utf8String, -1, -1, 0) != 0 else {
                throw OpenSslError.generalError(#line, getLastError())
            }
        }

        // MARK: Create extension for 'Subject sign tool'
        guard let subjectSignTool = WrappedPointer<OpaquePointer>({
            X509V3_EXT_nconf_nid(nil, nil, NID_subjectSignTool,
                                 "Средство электронной подписи: СКЗИ \"Рутокен ЭЦП 3.0\"")
        }, X509_EXTENSION_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { subjectSignTool.release() }

        // MARK: Create extension for 'Key usage'
        guard let keyUsageExt = WrappedPointer<OpaquePointer>({
            X509V3_EXT_nconf_nid(nil, nil, NID_key_usage,
                                 "digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment")

        }, X509_EXTENSION_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { keyUsageExt.release() }

        // MARK: Add ext key usage
        guard let exExtKeyUsage = WrappedPointer<OpaquePointer>({
            X509V3_EXT_conf_nid(nil, nil, NID_ext_key_usage, "clientAuth,emailProtection")
        }, X509_EXTENSION_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { exExtKeyUsage.release() }

        // MARK: Create extension for 'certificate policies'
        guard let obj = WrappedPointer<OpaquePointer>({
            OBJ_txt2obj("1.2.643.100.113.1", 0)
        }, ASN1_OBJECT_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { obj.release() }

        guard let polInfo = WrappedPointer<UnsafeMutablePointer<POLICYINFO>>(POLICYINFO_new, POLICYINFO_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { polInfo.release() }

        polInfo.pointer.pointee.policyid = obj.pointer

        guard let policiesExtension = WrappedPointer<OpaquePointer>({
            let policies: [UnsafeMutablePointer<POLICYINFO>] = [polInfo.pointer]
            var tmp = policies
            return tmp.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) -> OpaquePointer? in
                let cArray = ptr.baseAddress?.assumingMemoryBound(to: UnsafeMutablePointer<POLICYINFO>?.self)
                guard let stackPolicyInfo = WrappedPointer<OpaquePointer>({
                    create_stack_of_policyinfo(cArray, Int32(policies.count))
                }, exposed_sk_POLICYINFO_free) else {
                    return nil
                }
                defer { stackPolicyInfo.release() }

                return X509V3_EXT_i2d(NID_certificate_policies, 1, UnsafeMutableRawPointer(stackPolicyInfo.pointer))
            }
        }, X509_EXTENSION_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { policiesExtension.release() }

        // MARK: Add IdentificationKind (custom extension)
        guard let oid = WrappedPointer<OpaquePointer>({
            OBJ_txt2obj("1.2.643.100.114", 1)
        }, ASN1_OBJECT_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { oid.release() }

        // Set IdentificationKind as raw TLV, for possible values see:
        // https://datatracker.ietf.org/doc/html/rfc9215
        let valueData = Data([0x02, 0x01, 0x00])
        guard let valueOctetString = WrappedPointer<UnsafeMutablePointer<ASN1_OCTET_STRING>>(ASN1_OCTET_STRING_new, {
            ASN1_OCTET_STRING_free($0)
        }) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { valueOctetString.release() }

        try valueData.withUnsafeBytes {
            let pointerValueData = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
            guard 1 == ASN1_OCTET_STRING_set(valueOctetString.pointer, pointerValueData, Int32(valueData.count)) else {
                throw OpenSslError.generalError(#line, getLastError())
            }
        }

        guard let identificationKindByObj = WrappedPointer<OpaquePointer>({
            X509_EXTENSION_create_by_OBJ(nil, oid.pointer, 0, valueOctetString.pointer)
        }, X509_EXTENSION_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { identificationKindByObj.release() }

        // MARK: Add 'Subject sign tool' & 'Key usage' & 'ext key usage' & 'certificate policies' & 'IdentificationKind' extensions into container
        guard let stackOfExts = WrappedPointer<OpaquePointer>(exposed_sk_X509_EXTENSION_new_null, {
            exposed_sk_X509_EXTENSION_pop_free($0, X509_EXTENSION_free)
        }) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            stackOfExts.release()
        }

        var stackPtr: OpaquePointer? = stackOfExts.pointer
        guard X509v3_add_ext(&stackPtr, subjectSignTool.pointer, -1) != nil,
              X509v3_add_ext(&stackPtr, keyUsageExt.pointer, -1) != nil,
              X509v3_add_ext(&stackPtr, exExtKeyUsage.pointer, -1) != nil,
              X509v3_add_ext(&stackPtr, identificationKindByObj.pointer, -1) != nil,
              X509v3_add_ext(&stackPtr, policiesExtension.pointer, -1) != nil else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Add 'Private key usage period' extension into container
        if let start = info.startDate?.getString(as: "YYYYMMdd"),
           let end = info.endDate?.getString(as: "YYYYMMdd") {
            var valueStr = "ASN1:SEQUENCE:privateKeyUsagePeriod\n"
            valueStr += "[privateKeyUsagePeriod]\n"
            valueStr += "notBefore=IMP:0,GENERALIZEDTIME:\(start)000000Z\n"
            valueStr += "notAfter=IMP:1,GENERALIZEDTIME:\(end)000000Z"

            try addV3Extensions(to: stackOfExts, for: csr, exts: ["2.5.29.16": valueStr])
        }

        // MARK: Setting of the extensions for the request
        guard X509_REQ_add_extensions(csr.pointer, stackOfExts.pointer) == 1 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Setting of the public key
        guard X509_REQ_set_pubkey(csr.pointer, wrappedKey.pointer) == 1 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Sign of the request
        guard X509_REQ_sign(csr.pointer, wrappedKey.pointer, exposed_EVP_get_digestbynid(NID_id_GostR3410_2012_256)) > 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Read created request
        guard let wrappedBio = WrappedPointer<OpaquePointer>({ BIO_new(BIO_s_mem()) }, { BIO_free($0) }) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { wrappedBio.release() }

        guard PEM_write_bio_X509_REQ(wrappedBio.pointer, csr.pointer) == 1,
              let csr = bioToString(wrappedBio.pointer) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        return csr
    }

    func createCert(for csr: String, with caKey: Data, cert caCert: Data) throws -> Data {
        // MARK: Load the CSR
        guard let wrappedCsr = WrappedPointer<OpaquePointer>({
            guard let csrBio = stringToBio(csr) else { return nil }
            defer { csrBio.release() }

            guard let csr = PEM_read_bio_X509_REQ(csrBio.pointer, nil, nil, nil) else {
                return nil
            }
            return csr
        }, X509_REQ_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { wrappedCsr.release() }

        // MARK: Load a certificate of the CA
        guard let wrappedCaCert = WrappedX509(from: caCert) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { withExtendedLifetime(wrappedCaCert) {} }

        // MARK: Load a private key of the CA
        guard let privateKeyCa = wrapKey(caKey) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { privateKeyCa.release() }

        // MARK: Create a new certificate
        guard let generatedCert = WrappedX509() else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { withExtendedLifetime(generatedCert) {} }

        // MARK: Set version
        guard X509_set_version(generatedCert.wrappedPointer.pointer, Int(X509_VERSION_3)) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Generate and set a serial number
        guard let serialNumber = WrappedPointer<UnsafeMutablePointer<ASN1_OCTET_STRING>>(ASN1_INTEGER_new, { ASN1_INTEGER_free($0) }) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { serialNumber.release() }

        guard let bignum = WrappedPointer<OpaquePointer>(BN_new, { BN_free($0) }) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { bignum.release() }

        guard BN_pseudo_rand(bignum.pointer, 64, 0, 0) != 0,
              BN_to_ASN1_INTEGER(bignum.pointer, serialNumber.pointer) != nil else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        guard X509_set_serialNumber(generatedCert.wrappedPointer.pointer, serialNumber.pointer) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Set issuer name and subject_name
        guard X509_set_issuer_name(generatedCert.wrappedPointer.pointer, X509_get_subject_name(wrappedCaCert.wrappedPointer.pointer)) != 0,
              X509_set_subject_name(generatedCert.wrappedPointer.pointer, X509_REQ_get_subject_name(wrappedCsr.pointer)) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Set Date
        guard let asn1Before = WrappedPointer<UnsafeMutablePointer<ASN1_STRING>>({ X509_gmtime_adj(nil, 0) },
                                                                                 ASN1_STRING_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { asn1Before.release() }

        guard let asn1After = WrappedPointer<UnsafeMutablePointer<ASN1_STRING>>({ X509_gmtime_adj(nil, 60*60*24*365) },
                                                                                ASN1_STRING_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { asn1After.release() }

        guard X509_set1_notBefore(generatedCert.wrappedPointer.pointer, asn1Before.pointer) != 0,
              X509_set1_notAfter(generatedCert.wrappedPointer.pointer, asn1After.pointer) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Extracts the public key and set to the new certificate
        guard let publicKeyCsr = WrappedPointer<OpaquePointer>({ X509_REQ_get_pubkey(wrappedCsr.pointer) }, EVP_PKEY_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { publicKeyCsr.release() }

        guard X509_set_pubkey(generatedCert.wrappedPointer.pointer, publicKeyCsr.pointer) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Copy parameters
        guard let publicCaKey = WrappedPointer<OpaquePointer>({ X509_get_pubkey(wrappedCaCert.wrappedPointer.pointer) }, EVP_PKEY_free),
              EVP_PKEY_copy_parameters(publicCaKey.pointer, privateKeyCa.pointer) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { publicCaKey.release() }

        // MARK: Copy extensions
        guard let extensionStack = WrappedPointer<OpaquePointer>({
            X509_REQ_get_extensions(wrappedCsr.pointer)
        }, { exposed_sk_X509_EXTENSION_pop_free($0, X509_EXTENSION_free) }) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { extensionStack.release() }

        for i in 0..<exposed_sk_X509_EXTENSION_num(extensionStack.pointer) {
            guard let ext = exposed_sk_X509_EXTENSION_value(extensionStack.pointer, i),
                  X509_add_ext(generatedCert.wrappedPointer.pointer, ext, -1) != 0 else {
                throw OpenSslError.generalError(#line, getLastError())
            }
        }

        // MARK: Add subject key identifier
        var ctx = X509V3_CTX()
        X509V3_set_ctx(&ctx, wrappedCaCert.wrappedPointer.pointer, generatedCert.wrappedPointer.pointer, nil, nil, 0)

        guard let exKey = WrappedPointer<OpaquePointer>({
            X509V3_EXT_conf_nid(nil, &ctx, NID_subject_key_identifier, "hash")
        }, X509_EXTENSION_free),
              X509_add_ext(generatedCert.wrappedPointer.pointer, exKey.pointer, -1) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { exKey.release() }

        // MARK: Add authorityKeyIdentifier
        guard let exAuthority = WrappedPointer<OpaquePointer>({
            X509V3_EXT_conf_nid(nil, &ctx, NID_authority_key_identifier, "keyid,issuer:always")
        }, X509_EXTENSION_free),
              X509_add_ext(generatedCert.wrappedPointer.pointer, exAuthority.pointer, -1) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { exAuthority.release() }

        // MARK: Sign the certificate
        guard X509_sign(generatedCert.wrappedPointer.pointer, privateKeyCa.pointer,
                        exposed_EVP_get_digestbynid(NID_id_GostR3410_2012_256)) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Read created certificate
        guard let wrappedBio = WrappedPointer<OpaquePointer>({ BIO_new(BIO_s_mem()) }, { BIO_free($0) }) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { wrappedBio.release() }

        guard i2d_X509_bio(wrappedBio.pointer, generatedCert.wrappedPointer.pointer) > 0,
              let generatedCertData = bioToData(wrappedBio.pointer) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        return generatedCertData
    }

    func encryptDocument(for document: Data, with cert: Data) throws -> Data {
        guard let contentBio = dataToBio(document) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { contentBio.release() }

        guard let certStack = createX509Stack(with: [cert]) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { certStack.release() }

        /* Receiving encryption algorithm.
         To use other encryption modes and algorithms, replace rt_eng_nid_gost28147_cfb with:
         - NID_kuznyechik_ctr_acpkm_omac for KUZNYECHIK-CTR-ACPKM-OMAC
         - NID_magma_ctr_acpkm_omac for MAGMA-CTR-ACPKM-OMAC
         - NID_id_tc26_cipher_gostr3412_2015_kuznyechik_ctracpkm for KUZNYECHIK-CTR-ACPKM
         - NID_id_tc26_cipher_gostr3412_2015_magma_ctracpkm for MAGMA-CTR-ACPKM */
        guard let cipher = exposed_EVP_get_cipherbynid(Int32(rt_eng_nid_gost28147_cfb)) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        guard let cms = WrappedPointer<OpaquePointer>({
            CMS_encrypt(certStack.pointer, contentBio.pointer, cipher, UInt32(CMS_KEY_PARAM | CMS_BINARY))
        }, CMS_ContentInfo_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { cms.release() }

        let cmsLength = i2d_CMS_ContentInfo(cms.pointer, nil)
        guard cmsLength >= 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        var cmsData = Data(repeating: 0x00, count: Int(cmsLength))
        try cmsData.withUnsafeMutableBytes {
            var pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
            guard i2d_CMS_ContentInfo(cms.pointer, &pointer) >= 0 else {
                throw OpenSslError.generalError(#line, getLastError())
            }
        }
        return cmsData
    }

    func decryptCms(content: Data, wrappedKey: WrappedPointer<OpaquePointer>) throws -> Data {
        guard let cms = WrappedPointer<OpaquePointer>({
            return content.withUnsafeBytes {
                var pointer: UnsafePointer<UInt8>? = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
                return d2i_CMS_ContentInfo(nil, &pointer, content.count)
            }
        }, CMS_ContentInfo_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { cms.release() }

        guard let wrappedBio = WrappedPointer<OpaquePointer>({ BIO_new(BIO_s_mem()) }, { BIO_free($0) }) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer { wrappedBio.release() }

        guard CMS_decrypt(cms.pointer, wrappedKey.pointer, nil, nil, wrappedBio.pointer, 0) > 0,
              let decryptedData = bioToData(wrappedBio.pointer) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        return decryptedData
    }

    private func createX509Stack(with certs: [Data]) -> WrappedPointer<OpaquePointer>? {
        guard let wrappedStack = WrappedPointer<OpaquePointer>(exposed_sk_X509_new_null, exposed_sk_X509_pop_free) else {
            return nil
        }

        for cert in certs {
            guard let x509 = WrappedX509(from: cert) else { return nil }
            defer { withExtendedLifetime(x509) {} }

            guard 0 < exposed_sk_X509_push(wrappedStack.pointer, x509.wrappedPointer.pointer) else {
                return nil
            }

            // After x509 was added to stack we need to increment its reference counter to avoid unexpected resource free
            X509_up_ref(x509.wrappedPointer.pointer)
        }

        return wrappedStack
    }

    private func getLastError() -> String? {
        var errorString: String
        let errorCode = Int32(ERR_get_error())

        if errorCode == 0 {
            return nil
        }

        if let errorStr = ERR_reason_error_string(UInt(errorCode)) {
            errorString = String(validatingUTF8: errorStr)!
        } else {
            errorString = "Could not determine error reason."
        }

        return "ERROR: \(errorCode), reason: \(errorString)"
    }
}
