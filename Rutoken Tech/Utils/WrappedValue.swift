//
//  WrappedValue.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 26.04.2024.
//

class WrappedValue<T> {
    let value: T
    private let destructor: (T) -> Void

    init(_ value: T, _ destructor: @escaping (T) -> Void) {
        self.value = value
        self.destructor = destructor
    }

    deinit {
        destructor(value)
    }
}
