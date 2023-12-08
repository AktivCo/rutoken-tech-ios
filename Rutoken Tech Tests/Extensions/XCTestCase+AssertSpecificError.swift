//
//  XCTestCase+AssertSpecificError.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 22.11.2023.
//

import Combine
import XCTest


extension XCTestCase {
    func assertError<T, E: Error & Equatable>(
        _ expression: @autoclosure () throws -> T,
        throws error: E,
        in file: StaticString = #file,
        line: UInt = #line
    ) {
        var thrownError: Error?

        XCTAssertThrowsError(try expression(), file: file, line: line) {
            thrownError = $0
        }

        XCTAssertTrue(thrownError is E, "Unexpected error type: \(type(of: thrownError))", file: file, line: line)

        XCTAssertEqual(thrownError as? E, error, file: file, line: line)
    }

    func assertErrorAsync<T, E: Error & Equatable>(
        _ expression: @autoclosure () async throws -> T,
        throws error: E,
        in file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("No error thrown")
        } catch let thrownError {
            XCTAssertTrue(thrownError is E, "Unexpected error type: \(type(of: thrownError))", file: file, line: line)
            XCTAssertEqual(thrownError as? E, error, file: file, line: line)
        }
    }
}

