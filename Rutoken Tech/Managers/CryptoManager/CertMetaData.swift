//
//  CertMetaData.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 19.02.2024.
//

import Foundation


struct CertMetaData: Equatable {
    let keyId: String
    let tokenSerial: String

    let hash: String
    let name: String
    let jobTitle: String
    let companyName: String
    let keyAlgo: Pkcs11KeyAlgorithm
    let startDate: Date
    let expiryDate: Date

    init?(keyId: String, tokenSerial: String, from cert: Data) {
        guard let x509 = WrappedX509(from: cert),
              let subjectNameHash = x509.subjectNameHash,
              let commonName = x509.commonName,
              let title = x509.title,
              let organizationName = x509.organizationName,
              let notBefore = x509.notBefore,
              let notAfter = x509.notAfter,
              let algorithm = x509.publicKeyAlgorithm
        else { return nil }

        self.keyId = keyId
        self.tokenSerial = tokenSerial
        self.hash = subjectNameHash
        self.name = commonName
        self.jobTitle = title
        self.companyName = organizationName
        self.keyAlgo = algorithm
        self.startDate = notBefore
        self.expiryDate = notAfter
    }
}
