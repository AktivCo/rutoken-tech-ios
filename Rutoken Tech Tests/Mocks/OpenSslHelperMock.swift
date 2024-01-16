//
//  OpenSslHelperMock.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 18.01.2024.
//

@testable import Rutoken_Tech


class OpenSslHelperMock: OpenSslHelperProtocol {
    func createCsr(with wrappedKey: WrappedPointer, for request: CsrModel) throws -> String {
        try createCsrCallback(wrappedKey, request)
    }

    var createCsrCallback: (WrappedPointer, CsrModel) throws -> String = { _, _ in "" }
}
