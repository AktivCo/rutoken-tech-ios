//
//  XCTestCase+LinuxFulfillment.swift
//  Rutoken Tech Tests
//
//  Created by Никита Девятых on 20.12.2023.
//

#if swift(<5.9)
import XCTest


extension XCTestCase {
    func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval, enforceOrder: Bool = false) async {
        return await withCheckedContinuation { continuation in
            Thread.detachNewThread { [self] in
                wait(for: expectations, timeout: timeout, enforceOrder: enforceOrder)
                continuation.resume()
            }
        }
    }
}
#endif
