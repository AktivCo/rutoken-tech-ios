//
//  OpenSslHelperMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 18.01.2024.
//

import Foundation

@testable import Rutoken_Tech


class OpenSslHelperMock: OpenSslHelperProtocol {
    func createCsr(with wrappedKey: WrappedPointer<OpaquePointer>, for request: CsrModel) throws -> String {
        try createCsrCallback(wrappedKey, request)
    }

    var createCsrCallback: (WrappedPointer<OpaquePointer>, CsrModel) throws -> String = { _, _ in "" }

    func createCert(for csr: String, with caKey: Data, cert caCert: Data) throws -> Data {
        try createCertCallback()
    }

    var createCertCallback: () throws -> Data = { return Data() }

    func parseCert(_ cert: Data) throws -> CertModel {
        try parseCertCallback(cert)
    }

    var parseCertCallback: (Data) throws -> CertModel = { _ in
            .init(hash: "hash",
                  name: "Иванов Михаил Романович",
                  jobTitle: "Дизайнер",
                  companyName: "Рутокен",
                  keyAlgo: .gostR3410_2012_256,
                  expiryDate: "07.03.2024",
                  causeOfInvalid: nil)
    }
}
