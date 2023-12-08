//
//  Atomic+propertywrapper.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 15.12.2023.
//

import Foundation


@propertyWrapper struct Atomic<Value> {
    private let lock = NSLock()
    private var value: Value

    init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    var wrappedValue: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            value = newValue
        }
    }
}
