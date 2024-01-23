//
//  String+createPointer.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 24.01.2024.
//

extension String {
    func createPointer() -> WrappedPointer<UnsafeMutablePointer<UInt8>> {
        self.withCString(encodedAs: UTF8.self) {
            let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: self.count)
            ptr.initialize(from: $0, count: self.count)
            return WrappedPointer(ptr: ptr) { ptr in
                ptr.deallocate()
            }
        }
    }
}
