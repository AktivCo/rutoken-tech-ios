//
//  XCTestCase+ExpectationWaiter.swift
//  Rutoken Tech Tests
//
//  Created by Vova Badyaev on 11.03.2024.
//

import Combine
import XCTest


extension XCTestCase {
    @discardableResult
    func awaitPublisher<T: Publisher>(
        _ publisher: T,
        isInverted: Bool = false,
        timeout: TimeInterval = 3,
        doBefore: () throws -> Void = {},
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> Result<T.Output, T.Failure>? {
        var result: Result<T.Output, T.Failure>?

        let expectation = self.expectation(description: "Awaiting publisher")
        expectation.isInverted = isInverted

        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                    expectation.fulfill()
                case .finished:
                    break
                }
            },
            receiveValue: { value in
                result = .success(value)
                expectation.fulfill()
            }
        )
        defer {
            cancellable.cancel()
        }

        try doBefore()
        wait(for: [expectation], timeout: timeout)

        return result
    }

    @discardableResult
    func awaitPublisherUnwrapped<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 3,
        doBefore: () throws -> Void = {},
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Output {
        let result = try awaitPublisher(
            publisher,
            isInverted: false,
            timeout: timeout,
            doBefore: doBefore,
            file: file,
            line: line)

        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )

        return try unwrappedResult.get()
    }

    @discardableResult
    func awaitPublisherError<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 3,
        doBefore: () -> Void = {},
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Failure? {
        let result = try awaitPublisher(
            publisher,
            isInverted: false,
            timeout: timeout,
            doBefore: doBefore,
            file: file,
            line: line)

        var error: T.Failure?
        if case let .failure(receivedError) = result {
            error = receivedError
        }

        let unwrappedError = try XCTUnwrap(
            error,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )

        return unwrappedError
    }
}
