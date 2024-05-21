//
//  OpenSslHelperMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 18.01.2024.
//

import Foundation

@testable import Rutoken_Tech


class OpenSslHelperMock: OpenSslHelperProtocol {
    func createCsr(with wrappedKey: WrappedPointer<OpaquePointer>, for request: CsrModel, with info: CertInfo) throws -> String {
        try createCsrCallback(wrappedKey, request)
    }
    var createCsrCallback: (WrappedPointer<OpaquePointer>, CsrModel) throws -> String = { _, _ in "" }

    func createCert(for csr: String, with caKey: Data, cert caCert: Data) throws -> Data {
        try createCertCallback()
    }
    var createCertCallback: () throws -> Data = { return Data() }

    func signCms(for content: Data, wrappedKey: WrappedPointer<OpaquePointer>, cert: Data) throws -> String {
        try signCmsCallback()
    }
    func signCms(for content: Data, key: Data, cert: Data) throws -> String {
        try signCmsCallback()
    }
    var signCmsCallback: () throws -> String = { "" }

    func verifyCms(signedCms: String, for content: Data, with cert: Data, certChain: [Data]) throws -> VerifyCmsResult {
        try verifyCmsCallback()
    }
    var verifyCmsCallback: () throws -> VerifyCmsResult  = { .success }

    func encryptDocument(for content: Data, with cert: Data) throws -> Data {
        try encryptCmsCallback(content, cert)
    }
    var encryptCmsCallback: (Data, Data) throws -> Data = { _, _ in Data() }

    func decryptCms(content: Data, wrappedKey: WrappedPointer<OpaquePointer>) throws -> Data {
        try decryptCmsCallback(content, wrappedKey)
    }
    var decryptCmsCallback: (Data, WrappedPointer<OpaquePointer>) throws -> Data = { _, _ in Data() }
}
