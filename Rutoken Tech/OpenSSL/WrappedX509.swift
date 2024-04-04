//
//  WrappedX509.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 26.02.2024.
//

import Foundation


class WrappedX509 {
    private enum CertField {
        case commonName
        case title
        case organizationName

        var nidValue: Int32 {
            switch self {
            case .commonName: return NID_commonName
            case .title: return NID_title
            case .organizationName: return NID_organizationName
            }
        }
    }

    private let x509: WrappedPointer<OpaquePointer>

    init?() {
        guard let x509 = WrappedPointer(X509_new, X509_free) else {
            return nil
        }
        self.x509 = x509
    }

    init?(from bio: WrappedPointer<OpaquePointer>) {
        guard let x509 = WrappedPointer({
            PEM_read_bio_X509(bio.pointer, nil, nil, nil)
        }, X509_free) else {
            return nil
        }
        self.x509 = x509
    }

    convenience init?(from cert: Data) {
        if let pemString = String(data: cert, encoding: .utf8) {
            self.init(from: pemString)
        } else {
            self.init(with: cert)
        }
    }

    private init?(with data: Data) {
        guard let x509 = WrappedPointer<OpaquePointer>({
            guard let wrappedBio = dataToBio(data),
                  let ptr = d2i_X509_bio(wrappedBio.pointer, nil) else {
                return nil
            }
            return ptr
        }, X509_free) else {
            return nil
        }
        self.x509 = x509
    }

    init?(from cert: String) {
        guard let x509 = WrappedPointer<OpaquePointer>({
            guard let wrappedBio = stringToBio(cert),
                  let ptr = PEM_read_bio_X509(wrappedBio.pointer, nil, nil, nil) else {
                return nil
            }
            return ptr
        }, X509_free) else {
            return nil
        }
        self.x509 = x509
    }

    public var subjectNameHash: String? {
        let hash = X509_subject_name_hash(x509.pointer)
        guard hash != 0 else {
            return nil
        }

        return String(hash)
    }

    public var publicKeyAlgorithm: KeyAlgorithm? {
        guard let publicKey = WrappedPointer({
            X509_get_pubkey(x509.pointer)
        }, EVP_PKEY_free) else {
            return nil
        }

        guard EVP_PKEY_get_id(publicKey.pointer) == NID_id_GostR3410_2012_256 else {
            return nil
        }

        return .gostR3410_2012_256
    }

    public var commonName: String? {
        getValue(for: .commonName)
    }

    public var title: String? {
        getValue(for: .title)
    }

    public var organizationName: String? {
        getValue(for: .organizationName)
    }

    public var notBefore: Date? {
        guard let notBefore = X509_get0_notBefore(x509.pointer) else {
            return nil
        }

        return notBefore.asDate()
    }

    public var notAfter: Date? {
        guard let notAfter = X509_get0_notAfter(x509.pointer) else {
            return nil
        }

        return notAfter.asDate()
    }

    private func getValue(for field: CertField) -> String? {
        guard let subjectName = X509_get_subject_name(x509.pointer) else {
            return nil
        }

        let index = X509_NAME_get_index_by_NID(subjectName, field.nidValue, -1)
        guard index != -1 else {
            return nil
        }

        guard let nameEntry = X509_NAME_get_entry(subjectName, index),
              let nameASN1 = X509_NAME_ENTRY_get_data(nameEntry)
        else {
            return nil
        }

        let len = ASN1_STRING_length(nameASN1)
        guard let name = ASN1_STRING_data(nameASN1),
              len > 0 else {
            return nil
        }

        return String(cString: name)
    }
}

private extension UnsafePointer where Pointee == ASN1_TIME {
    func asDate() -> Date? {
        guard let wrappedBio = WrappedPointer({ BIO_new(BIO_s_mem()) }, BIO_free) else {
            return nil
        }

        guard ASN1_TIME_print(wrappedBio.pointer, self) == 1 else {
            return nil
        }

        guard let str = bioToString(wrappedBio.pointer) else {
            return nil
        }

        // When handling ASN1_TIME, we always assume the format MMM DD HH:MM:SS YYYY [GMT]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd HH:mm:ss yyyy ZZZ"
        dateFormatter.locale = Locale(identifier: "en_US")
        guard let date = dateFormatter.date(from: str) else {
            return nil
        }

        return date
    }
}
