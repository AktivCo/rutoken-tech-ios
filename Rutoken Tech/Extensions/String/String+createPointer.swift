//
//  String+createPointer.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 24.01.2024.
//

extension String {
    func createPointer() -> WrappedPointer<UnsafeMutablePointer<UInt8>>? {
        self.withCString(encodedAs: UTF8.self) { stringPtr in
            WrappedPointer<UnsafeMutablePointer<UInt8>>({
                let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: self.count)
                ptr.initialize(from: stringPtr, count: self.count)
                return ptr
            }, { [count = self.count] in
                $0.deinitialize(count: count)
                $0.deallocate()
            })
        }
    }
}
