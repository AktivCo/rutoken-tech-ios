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
    func createCsr(with wrappedKey: WrappedPointer<OpaquePointer>, for request: CsrModel) throws -> String
    func parseCert(_ cert: Data) throws -> CertModel
    func createCert(for csr: String, with caKeyStr: String, and caCertStr: String) throws -> Data
}

class OpenSslHelper: OpenSslHelperProtocol {
    let engine: RtEngineWrapperProtocol

    init(engine: RtEngineWrapperProtocol) {
        self.engine = engine

        let r = OPENSSL_init_crypto(UInt64(OPENSSL_INIT_NO_LOAD_CONFIG | OPENSSL_INIT_NO_ATEXIT), nil)
        assert(r == 1)
    }

    deinit {
        OPENSSL_cleanup()
    }

    func createCsr(with wrappedKey: WrappedPointer<OpaquePointer>, for request: CsrModel) throws -> String {
        guard let bio = BIO_new(BIO_s_mem()) else { throw OpenSslError.generalError(#line, getLastError()) }
        defer {
            BIO_free(bio)
        }

        guard let csr = X509_REQ_new() else { throw OpenSslError.generalError(#line, getLastError()) }
        defer {
            X509_REQ_free(csr)
        }

        guard let subject = X509_REQ_get_subject_name(csr) else {
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
        guard let subjectSignTool = X509V3_EXT_nconf_nid(nil, nil, NID_subjectSignTool,
                                                         "Средство электронной подписи: СКЗИ \"Рутокен ЭЦП 3.0\"") else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            X509_EXTENSION_free(subjectSignTool)
        }

        // MARK: Create extension for 'Key usage'
        guard let keyUsageExt = X509V3_EXT_nconf_nid(nil, nil, NID_key_usage,
                                                     "digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment") else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            X509_EXTENSION_free(keyUsageExt)
        }

        // MARK: Add ext key usage
        guard let exExtKeyUsage = X509V3_EXT_conf_nid(nil, nil, NID_ext_key_usage, "clientAuth,emailProtection") else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Create extension for 'certificate policies'
        var policies: [UnsafeMutablePointer<POLICYINFO>] = []
        guard let obj = OBJ_txt2obj("1.2.643.100.113.1", 0) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            ASN1_OBJECT_free(obj)
        }
        guard let polInfo = POLICYINFO_new() else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            POLICYINFO_free(polInfo)
        }
        polInfo.pointee.policyid = obj
        policies.append(polInfo)

        var policiesExtension = X509_EXTENSION_new()
        defer {
            X509_EXTENSION_free(policiesExtension)
        }

        let countPolicies = policies.count
        policies.withUnsafeMutableBytes { pointer in
            let cArray = pointer.baseAddress?.assumingMemoryBound(to: UnsafeMutablePointer<POLICYINFO>?.self)
            let stackPolicyInfo = create_stack_of_policyinfo(cArray, Int32(countPolicies))
            defer {
                exposed_sk_POLICYINFO_free(stackPolicyInfo)
            }
            policiesExtension = X509V3_EXT_i2d(NID_certificate_policies, 1, UnsafeMutableRawPointer(stackPolicyInfo))
        }

        // MARK: Add IdentificationKind (custom extension)
        guard let oid = OBJ_txt2obj("1.2.643.100.114", 1) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            ASN1_OBJECT_free(oid)
        }
        // Set IdentificationKind as raw TLV, for possible values see:
        // https://datatracker.ietf.org/doc/html/rfc9215
        let valueData = Data([0x02, 0x01, 0x00])
        let valueOctetString = ASN1_OCTET_STRING_new()
        defer {
            ASN1_OCTET_STRING_free(valueOctetString)
        }
        valueData.withUnsafeBytes {
            let pointerValueData = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
            ASN1_OCTET_STRING_set(valueOctetString, pointerValueData, Int32(valueData.count))
        }
        guard let identificationKindByObj = X509_EXTENSION_create_by_OBJ(nil, oid, 0, valueOctetString) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Add 'Subject sign tool' & 'Key usage' & 'ext key usage' & 'certificate policies' & 'IdentificationKind' extensions into container
        var extensions: OpaquePointer?
        guard X509v3_add_ext(&extensions, subjectSignTool, -1) != nil,
              X509v3_add_ext(&extensions, keyUsageExt, -1) != nil,
              X509v3_add_ext(&extensions, exExtKeyUsage, -1) != nil,
              X509v3_add_ext(&extensions, identificationKindByObj, -1) != nil,
              X509v3_add_ext(&extensions, policiesExtension, -1) != nil else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            exposed_sk_X509_EXTENSION_pop_free(extensions, X509_EXTENSION_free)
        }

        // MARK: Setting of the extensions for the request
        guard X509_REQ_add_extensions(csr, extensions) == 1 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Setting of the public key
        guard X509_REQ_set_pubkey(csr, wrappedKey.pointer) == 1 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Sign of the request
        guard X509_REQ_sign(csr, wrappedKey.pointer, exposed_EVP_get_digestbynid(NID_id_GostR3410_2012_256)) > 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Read created request
        guard let bio = BIO_new(BIO_s_mem()) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            BIO_free(bio)
        }
        guard PEM_write_bio_X509_REQ(bio, csr) == 1 else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        return bioToString(bio: bio)
    }

    func createCert(for csr: String, with caKeyStr: String, and caCertStr: String) throws -> Data {
        // MARK: Load the CSR
        let csrPointer = csr.cString(using: .utf8)
        guard let csrBio = BIO_new(BIO_s_mem()) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            BIO_free(csrBio)
        }
        guard BIO_puts(csrBio, csrPointer) > 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        guard let csr = PEM_read_bio_X509_REQ(csrBio, nil, nil, nil) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            X509_REQ_free(csr)
        }

        // MARK: Load a certificate of the CA
        guard let caCertPointer = caCertStr.cString(using: .utf8) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        guard let caCertBio = BIO_new(BIO_s_mem()) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            BIO_free(caCertBio)
        }
        guard BIO_puts(caCertBio, caCertPointer) > 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        guard let caCert = PEM_read_bio_X509(caCertBio, nil, nil, nil) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            X509_free(caCert)
        }

        // MARK: Load a private key of the CA
        guard let caKeyPointer = caKeyStr.cString(using: .utf8) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        guard let caKeyBio = BIO_new(BIO_s_mem()) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            BIO_free(caKeyBio)
        }
        guard BIO_puts(caKeyBio, caKeyPointer) > 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        guard let privateKeyCa = PEM_read_bio_PrivateKey(caKeyBio, nil, nil, nil) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            EVP_PKEY_free(privateKeyCa)
        }

        // MARK: Create a new certificate
        guard let generatedCert = X509_new() else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            X509_free(generatedCert)
        }
        // MARK: Set version
        guard X509_set_version(generatedCert, Int(X509_VERSION_3)) != 0 else {
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
        guard X509_set_serialNumber(generatedCert, serialNumber) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Set issuer name and subject_name
        guard X509_set_issuer_name(generatedCert, X509_get_subject_name(caCert)) != 0,
              X509_set_subject_name(generatedCert, X509_REQ_get_subject_name(csr)) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Set Date
        guard X509_set1_notBefore(generatedCert, X509_gmtime_adj(nil, 0)) != 0,
              X509_set1_notAfter(generatedCert, X509_gmtime_adj(nil, 60*60*24*365)) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Extracts the public key and set to the new certificate
        guard let publicKeyCsr = X509_REQ_get_pubkey(csr) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            EVP_PKEY_free(publicKeyCsr)
        }
        guard X509_set_pubkey(generatedCert, publicKeyCsr) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Copy parameters
        guard let publicCaKey = X509_get_pubkey(caCert) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            EVP_PKEY_free(publicCaKey)
        }
        guard EVP_PKEY_copy_parameters(publicCaKey, privateKeyCa) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Copy extensions
        let extensionStack = X509_REQ_get_extensions(csr)
        for i in 0..<exposed_sk_X509_EXTENSION_num(extensionStack) {
            guard let ext = exposed_sk_X509_EXTENSION_value(extensionStack, i),
                  X509_add_ext(generatedCert, ext, -1) != 0 else {
                throw OpenSslError.generalError(#line, getLastError())
            }
        }

        // MARK: Add subject key identifier
        var ctx = X509V3_CTX()
        X509V3_set_ctx(&ctx, caCert, generatedCert, nil, nil, 0)

        guard let exKey = X509V3_EXT_conf_nid(nil, &ctx, NID_subject_key_identifier, "hash"),
              X509_add_ext(generatedCert, exKey, -1) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Add authorityKeyIdentifier
        guard let exAuthority = X509V3_EXT_conf_nid(nil, &ctx, NID_authority_key_identifier, "keyid,issuer:always"),
              X509_add_ext(generatedCert, exAuthority, -1) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Sign the certificate
        guard X509_sign(generatedCert, privateKeyCa,
                        exposed_EVP_get_digestbynid(NID_id_GostR3410_2012_256)) != 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: Read created certificate
        guard let bio = BIO_new(BIO_s_mem()) else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            BIO_free(bio)
        }
        guard i2d_X509_bio(bio, generatedCert) > 0 else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        guard let generatedCertData = bioToData(bio) else {
            throw OpenSslError.generalError(#line, "Something went wrong during converting BIO to Data")
        }
        return generatedCertData
    }

    func bioToData(_ bio: OpaquePointer) -> Data? {
        let len = BIO_ctrl(bio, BIO_CTRL_PENDING, 0, nil)
        var buffer = [UInt8](repeating: 0, count: len + 1)
        let bytesRead = BIO_read(bio, &buffer, Int32(buffer.count))
        guard bytesRead > 0 else { return nil }
        return Data(bytes: buffer, count: Int(bytesRead))
    }

    func parseCert(_ cert: Data) throws -> CertModel {
        guard let wrappedX509 = WrappedX509(from: cert) else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        guard let commonName = wrappedX509.commonName,
              let title = wrappedX509.title,
              let organizationName = wrappedX509.organizationName,
              let notBefore = wrappedX509.notBefore,
              let notAfter = wrappedX509.notAfter,
              let algorithm = wrappedX509.publicKeyAlgorithm
        else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        var reason: CertInvalidReason?
        if Date() > notAfter {
            reason = .expired
        } else if notBefore > Date() {
            reason = .notStartedBefore(notBefore)
        }

        return .init(name: commonName,
                     jobTitle: title,
                     companyName: organizationName,
                     keyAlgo: algorithm,
                     expiryDate: notAfter.getString(with: "dd.MM.YYYY"),
                     causeOfInvalid: reason)
    }

    private func bioToString(bio: OpaquePointer) -> String {
        let len = BIO_ctrl(bio, BIO_CTRL_PENDING, 0, nil)
        var buffer = [CChar](repeating: 0, count: len + 1)
        BIO_read(bio, &buffer, Int32(len))

        // Ensure last value is 0 (null terminated) otherwise we get buffer overflow!
        buffer[len] = 0
        let ret = String(cString: buffer)
        return ret
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
