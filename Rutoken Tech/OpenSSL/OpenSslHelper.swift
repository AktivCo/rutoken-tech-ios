//
//  OpenSslHelper.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 15.01.2024.
//

import Foundation


enum OpenSslError: Error, Equatable {
    case generalError(UInt32, String?)
}

protocol OpenSslHelperProtocol {
    func createCsr(with wrappedKey: WrappedPointer<OpaquePointer>, for request: CsrModel, with info: CertInfo) throws -> String
    func createCert(for csr: String, with caKey: Data, cert caCert: Data) throws -> Data
    func signCms(for content: Data, wrappedKey: WrappedPointer<OpaquePointer>, cert: Data) throws -> String
    func signCms(for content: Data, key: Data, cert: Data) throws -> String
    func verifyCms(signedCms: String, for content: Data, with cert: Data, certChain: [Data]) throws -> VerifyCmsResult
    func encryptDocument(for content: Data, with cert: Data) throws -> Data
}

enum VerifyCmsResult {
    case success
    case failedChain
    case invalidSignature(OpenSslError)
}

class OpenSslHelper: OpenSslHelperProtocol {
    private let requestExtensionsSection = "req_extensions"
    private let requestAttributesSection = "req_attributes"

    let engine: RtEngineWrapperProtocol

    init(engine: RtEngineWrapperProtocol) {
        self.engine = engine

        let r = OPENSSL_init_crypto(UInt64(OPENSSL_INIT_NO_LOAD_CONFIG | OPENSSL_INIT_NO_ATEXIT), nil)
        assert(r == 1)
    }

    deinit {
        OPENSSL_cleanup()
    }

    func signCms(for content: Data, wrappedKey: WrappedPointer<OpaquePointer>, cert: Data) throws -> String {
        guard let contentBio = dataToBio(content),
              let x509 = WrappedX509(from: cert)
        else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        guard let cms = WrappedPointer<OpaquePointer>({
            CMS_sign(x509.wrappedPointer.pointer, wrappedKey.pointer, nil,
                     contentBio.pointer, UInt32(CMS_BINARY | CMS_NOSMIMECAP | CMS_DETACHED))
        }, CMS_ContentInfo_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

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

    func signCms(for content: Data, key: Data, cert: Data) throws -> String {
        guard let privateKey = wrapKey(key) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        return try self.signCms(for: content, wrappedKey: privateKey, cert: cert)
    }

    func verifyCms(signedCms: String, for content: Data, with cert: Data, certChain: [Data]) throws -> VerifyCmsResult {
        var rawBase64Cms = signedCms
            .replacingOccurrences(of: "-----BEGIN CMS-----", with: "")
            .replacingOccurrences(of: "-----END CMS-----", with: "")

        rawBase64Cms.removeAll { $0 == "\n" }

        guard let contentBio = dataToBio(content),
              let certsStack = createX509Stack(with: [cert]),
              let certStore = WrappedPointer<OpaquePointer>(X509_STORE_new, X509_STORE_free),
              let cms = WrappedPointer<OpaquePointer>({
                  guard let data = rawBase64Cms.data(using: .utf8),
                        let cmsData = Data(base64Encoded: data) else {
                      return nil
                  }

                  return cmsData.withUnsafeBytes {
                      var pointer: UnsafePointer<UInt8>? = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
                      guard let pointer = d2i_CMS_ContentInfo(nil, &pointer, data.count) else {
                          return nil
                      }
                      return pointer
                  }
              }, CMS_ContentInfo_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        for cert in certChain {
            guard let caCert = WrappedX509(from: cert),
                  X509_STORE_add_cert(certStore.pointer, caCert.wrappedPointer.pointer) == 1 else {
                throw OpenSslError.generalError(#line, getLastError())
            }
        }

        guard CMS_verify(cms.pointer,
                         certsStack.pointer,
                         certStore.pointer,
                         contentBio.pointer,
                         nil,
                         UInt32(CMS_BINARY)) == 1 else {
            // If we receive an error on CMS verify we try to verify without chain cheking
            // and send appropriate error
            guard CMS_verify(cms.pointer,
                             certsStack.pointer,
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
        guard let confFileBio = stringToBio(resultString),
              NCONF_load_bio(conf.pointer, confFileBio.pointer, &eline) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        return conf
    }

    private func addV3Extensions(request: WrappedPointer<OpaquePointer>, exts: [String: String]) throws {
        guard let stackOfExts = WrappedPointer<OpaquePointer>(exposed_sk_X509_EXTENSION_new_null, {
            exposed_sk_X509_EXTENSION_pop_free($0, X509_EXTENSION_free)
        }) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        for ext in exts {
            let extNid = OBJ_txt2nid(ext.key.cString(using: .utf8))
            let extensionName = extNid == NID_undef ? ext.key : String(cString: OBJ_nid2sn(extNid))
            let value = ext.value

            var extCtx = X509V3_CTX()
            let conf = try makeConfig(name: extensionName, value: value)

            X509V3_set_ctx(&extCtx, nil, nil, request.pointer, nil, 0)
            X509V3_set_nconf(&extCtx, conf.pointer)

            var stackPtr: OpaquePointer? = stackOfExts.pointer
            guard X509V3_EXT_add_nconf_sk(conf.pointer, &extCtx, requestExtensionsSection, &stackPtr) != 0 else {
                throw OpenSslError.generalError(#line, getLastError())
            }
        }
        guard X509_REQ_add_extensions(request.pointer, stackOfExts.pointer) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }
    }

    func createCsr(with wrappedKey: WrappedPointer<OpaquePointer>, for request: CsrModel, with info: CertInfo) throws -> String {
        guard let csr = WrappedPointer<OpaquePointer>(X509_REQ_new, X509_REQ_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        guard let subject = X509_REQ_get_subject_name(csr.pointer) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Add subjects entry
        for entry in request.subjects {
            guard X509_NAME_add_entry_by_txt(subject,
                                             entry.key.rawValue,
                                             entry.value.hasCyrillic ? MBSTRING_UTF8 : MBSTRING_ASC,
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

        // MARK: Create extension for 'Key usage'
        guard let keyUsageExt = WrappedPointer<OpaquePointer>({
            X509V3_EXT_nconf_nid(nil, nil, NID_key_usage,
                                 "digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment")

        }, X509_EXTENSION_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Add ext key usage
        guard let exExtKeyUsage = WrappedPointer<OpaquePointer>({
            X509V3_EXT_conf_nid(nil, nil, NID_ext_key_usage, "clientAuth,emailProtection")
        }, X509_EXTENSION_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Create extension for 'certificate policies'
        guard let obj = WrappedPointer<OpaquePointer>({
            OBJ_txt2obj("1.2.643.100.113.1", 0)
        }, ASN1_OBJECT_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        guard let polInfo = WrappedPointer<UnsafeMutablePointer<POLICYINFO>>(POLICYINFO_new, POLICYINFO_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
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
                return X509V3_EXT_i2d(NID_certificate_policies, 1, UnsafeMutableRawPointer(stackPolicyInfo.pointer))
            }
        }, X509_EXTENSION_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Add IdentificationKind (custom extension)
        guard let oid = WrappedPointer<OpaquePointer>({
            OBJ_txt2obj("1.2.643.100.114", 1)
        }, ASN1_OBJECT_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // Set IdentificationKind as raw TLV, for possible values see:
        // https://datatracker.ietf.org/doc/html/rfc9215
        let valueData = Data([0x02, 0x01, 0x00])
        guard let valueOctetString = WrappedPointer<UnsafeMutablePointer<ASN1_OCTET_STRING>>(ASN1_OCTET_STRING_new, {
            ASN1_OCTET_STRING_free($0)
        }) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
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

        // MARK: Add 'Subject sign tool' & 'Key usage' & 'ext key usage' & 'certificate policies' & 'IdentificationKind' extensions into container
        var extensions: OpaquePointer?
        guard X509v3_add_ext(&extensions, subjectSignTool.pointer, -1) != nil,
              X509v3_add_ext(&extensions, keyUsageExt.pointer, -1) != nil,
              X509v3_add_ext(&extensions, exExtKeyUsage.pointer, -1) != nil,
              X509v3_add_ext(&extensions, identificationKindByObj.pointer, -1) != nil,
              X509v3_add_ext(&extensions, policiesExtension.pointer, -1) != nil else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            exposed_sk_X509_EXTENSION_pop_free(extensions, X509_EXTENSION_free)
        }

        // MARK: Setting of the extensions for the request
        guard X509_REQ_add_extensions(csr.pointer, extensions) == 1 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        if let start = info.startDate?.getString(as: "YYYYMMdd"),
           let end = info.endDate?.getString(as: "YYYYMMdd") {
            var valueStr = "ASN1:SEQUENCE:privateKeyUsagePeriod\n"
            valueStr += "[privateKeyUsagePeriod]\n"
            valueStr += "notBefore=IMP:0,GENERALIZEDTIME:\(start)000000Z\n"
            valueStr += "notAfter=IMP:1,GENERALIZEDTIME:\(end)000000Z"

            try addV3Extensions(request: csr, exts: ["2.5.29.16": valueStr])
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
        guard let wrappedBio = WrappedPointer<OpaquePointer>({ BIO_new(BIO_s_mem()) }, { BIO_free($0) }),
              PEM_write_bio_X509_REQ(wrappedBio.pointer, csr.pointer) == 1,
              let csr = bioToString(wrappedBio.pointer) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        return csr
    }

    func createCert(for csr: String, with caKey: Data, cert caCert: Data) throws -> Data {
        // MARK: Load the CSR
        guard let wrappedCsr = WrappedPointer<OpaquePointer>({
            guard let csrBio = stringToBio(csr),
                  let csr = PEM_read_bio_X509_REQ(csrBio.pointer, nil, nil, nil) else {
                return nil
            }
            return csr
        }, X509_REQ_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Load a certificate of the CA
        guard let wrappedCaCert = WrappedX509(from: caCert) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Load a private key of the CA
        guard let privateKeyCa = wrapKey(caKey) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Create a new certificate
        guard let generatedCert = WrappedX509() else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        // MARK: Set version
        guard X509_set_version(generatedCert.wrappedPointer.pointer, Int(X509_VERSION_3)) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Generate and set a serial number
        let serialNumber = ASN1_INTEGER_new()
        defer {
            ASN1_INTEGER_free(serialNumber)
        }
        guard let bignum = BN_new() else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            BN_free(bignum)
        }
        guard BN_pseudo_rand(bignum, 64, 0, 0) != 0,
              BN_to_ASN1_INTEGER(bignum, serialNumber) != nil else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        guard X509_set_serialNumber(generatedCert.wrappedPointer.pointer, serialNumber) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Set issuer name and subject_name
        guard X509_set_issuer_name(generatedCert.wrappedPointer.pointer, X509_get_subject_name(wrappedCaCert.wrappedPointer.pointer)) != 0,
              X509_set_subject_name(generatedCert.wrappedPointer.pointer, X509_REQ_get_subject_name(wrappedCsr.pointer)) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Set Date
        guard let asn1Before = WrappedPointer<UnsafeMutablePointer<ASN1_STRING>>({ X509_gmtime_adj(nil, 0) }, ASN1_STRING_free),
              let asn1After = WrappedPointer<UnsafeMutablePointer<ASN1_STRING>>({ X509_gmtime_adj(nil, 60*60*24*365) }, ASN1_STRING_free),
              X509_set1_notBefore(generatedCert.wrappedPointer.pointer, asn1Before.pointer) != 0,
              X509_set1_notAfter(generatedCert.wrappedPointer.pointer, asn1After.pointer) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Extracts the public key and set to the new certificate
        guard let publicKeyCsr = WrappedPointer<OpaquePointer>({ X509_REQ_get_pubkey(wrappedCsr.pointer) }, EVP_PKEY_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        guard X509_set_pubkey(generatedCert.wrappedPointer.pointer, publicKeyCsr.pointer) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Copy parameters
        guard let publicCaKey = WrappedPointer<OpaquePointer>({ X509_get_pubkey(wrappedCaCert.wrappedPointer.pointer) }, EVP_PKEY_free),
              EVP_PKEY_copy_parameters(publicCaKey.pointer, privateKeyCa.pointer) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Copy extensions
        guard let extensionStack = WrappedPointer<OpaquePointer>({
            X509_REQ_get_extensions(wrappedCsr.pointer)
        }, {
            exposed_sk_X509_EXTENSION_pop_free($0, X509_EXTENSION_free)
        }) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
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

        // MARK: Add authorityKeyIdentifier
        guard let exAuthority = WrappedPointer<OpaquePointer>({
            X509V3_EXT_conf_nid(nil, &ctx, NID_authority_key_identifier, "keyid,issuer:always")
        }, X509_EXTENSION_free),
              X509_add_ext(generatedCert.wrappedPointer.pointer, exAuthority.pointer, -1) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Sign the certificate
        guard X509_sign(generatedCert.wrappedPointer.pointer, privateKeyCa.pointer,
                        exposed_EVP_get_digestbynid(NID_id_GostR3410_2012_256)) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Read created certificate
        guard let wrappedBio = WrappedPointer<OpaquePointer>({ BIO_new(BIO_s_mem()) }, { BIO_free($0) }),
              i2d_X509_bio(wrappedBio.pointer, generatedCert.wrappedPointer.pointer) > 0,
              let generatedCertData = bioToData(wrappedBio.pointer) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        return generatedCertData
    }

    func encryptDocument(for document: Data, with cert: Data) throws -> Data {
        guard let contentBio = dataToBio(document),
              let certStack = createX509Stack(with: [cert]),
              /* Receiving encryption algorithm.
               To use other encryption modes and algorithms, replace rt_eng_nid_gost28147_cfb with:
               - NID_kuznyechik_ctr_acpkm_omac for KUZNYECHIK-CTR-ACPKM-OMAC
               - NID_magma_ctr_acpkm_omac for MAGMA-CTR-ACPKM-OMAC
               - NID_id_tc26_cipher_gostr3412_2015_kuznyechik_ctracpkm for KUZNYECHIK-CTR-ACPKM
               - NID_id_tc26_cipher_gostr3412_2015_magma_ctracpkm for MAGMA-CTR-ACPKM */
              let cipher = exposed_EVP_get_cipherbynid(Int32(rt_eng_nid_gost28147_cfb)) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        guard let cms = WrappedPointer<OpaquePointer>({
            CMS_encrypt(certStack.pointer, contentBio.pointer, cipher, UInt32(CMS_KEY_PARAM | CMS_BINARY))
        }, CMS_ContentInfo_free) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

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

    private func createX509Stack(with certs: [Data]) -> WrappedPointer<OpaquePointer>? {
        guard let wrappedStack = WrappedPointer<OpaquePointer>(exposed_sk_X509_new_null, exposed_sk_X509_pop_free) else {
            return nil
        }

        for cert in certs {
            guard let x509 = WrappedX509(from: cert) else {
                return nil
            }
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
