//
//  OpenSslHelper.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 15.01.2024.
//

import Foundation


enum OpenSslError: Error {
    case generalError(UInt32, String?)
}

protocol OpenSslHelperProtocol {
    func createCsr(with wrappedKey: WrappedPointer<OpaquePointer>, for request: CsrModel) throws -> String
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

        // MARK: - Add subjects entry
        for entry in request.subjects {
            guard X509_NAME_add_entry_by_txt(subject,
                                             entry.key.rawValue,
                                             entry.value.hasCyrillic ? MBSTRING_UTF8 : MBSTRING_ASC,
                                             NSString(string: entry.value).utf8String, -1, -1, 0) != 0 else {
                throw OpenSslError.generalError(#line, getLastError())
            }
        }

        // MARK: - Create extension for 'Subject sign tool'
        guard let subjectSignTool = X509V3_EXT_nconf_nid(nil, nil, NID_subjectSignTool,
                                                         "Средство электронной подписи: СКЗИ \"Рутокен ЭЦП 3.0\"") else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            X509_EXTENSION_free(subjectSignTool)
        }

        // MARK: - Create extension for 'Key usage'
        guard let keyUsageExt = X509V3_EXT_nconf_nid(nil, nil, NID_key_usage,
                                                     "digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment") else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            X509_EXTENSION_free(keyUsageExt)
        }

        // MARK: - Add 'Subject sign tool' & 'Key usage' extensions into container
        var extensions: OpaquePointer?
        guard X509v3_add_ext(&extensions, subjectSignTool, -1) != nil,
              X509v3_add_ext(&extensions, keyUsageExt, -1) != nil else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            exposed_sk_X509_EXTENSION_pop_free(extensions, X509_EXTENSION_free)
        }

        // MARK: - Setting of the extensions for the request
        guard X509_REQ_add_extensions(csr, extensions) == 1 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: - Setting of the public key
        guard X509_REQ_set_pubkey(csr, wrappedKey.pointer) == 1 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: - Sign of the request
        guard X509_REQ_sign(csr, wrappedKey.pointer, exposed_EVP_get_digestbynid(NID_id_GostR3410_2012_256)) > 1 else {
            throw OpenSslError.generalError(#line, getLastError())
        }

        // MARK: - Read created request
        guard let bio = BIO_new(BIO_s_mem()),
              PEM_write_bio_X509_REQ(bio, csr) == 1 else {
            throw OpenSslError.generalError(#line, getLastError())
        }
        defer {
            BIO_free(bio)
        }

        return bioToString(bio: bio)
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
