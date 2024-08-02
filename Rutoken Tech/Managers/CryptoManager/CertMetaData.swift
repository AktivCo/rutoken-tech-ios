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

    let body: Data
    let hash: String
    let name: String
    let jobTitle: String?
    let companyName: String?
    let keyAlgo: Pkcs11KeyAlgorithm
    let startDate: Date
    let expiryDate: Date

    init?(keyId: String, tokenSerial: String, from cert: Data) {
        guard let x509 = WrappedX509(from: cert),
              let subjectNameHash = x509.subjectNameHash,
              let commonName = x509.commonName,
              let notBefore = x509.notBefore,
              let notAfter = x509.notAfter,
              let algorithm = x509.publicKeyAlgorithm
        else { return nil }

        self.keyId = keyId
        self.tokenSerial = tokenSerial
        self.body = cert
        self.hash = subjectNameHash
        self.name = commonName
        self.jobTitle = x509.title
        self.companyName = x509.organizationName
        self.keyAlgo = algorithm
        self.startDate = notBefore
        self.expiryDate = notAfter
    }

#if DEBUG
    init(keyId: String, tokenSerial: String, hash: String, name: String,
         jobTitle: String, companyName: String, keyAlgo: Pkcs11KeyAlgorithm = .gostR3410_2012_256,
         startDate: Date, expiryDate: Date) {
        self.keyId = keyId
        self.tokenSerial = tokenSerial
        self.hash = hash
        self.name = name
        self.jobTitle = jobTitle
        self.companyName = companyName
        self.keyAlgo = keyAlgo
        self.startDate = startDate
        self.expiryDate = expiryDate

        self.body = Data()
    }
#endif
}
