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

    func createCert(for csr: String, with caKeyStr: String, and caCertStr: String) throws -> Data {
        try createCertCallback()
    }

    var createCertCallback: () throws -> Data = { return Data() }
}
