//
//  WrappedPointer.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 18.01.2024.
//

class WrappedPointer<T> {
    let pointer: T
    private let destructor: (T) -> Any

    init?(_ constructor: () -> T?, _ destructor: @escaping (T) -> Any) {
        guard let ptr = constructor() else { return nil }
        self.pointer = ptr
        self.destructor = destructor
    }

    deinit {
        _ = destructor(pointer)
    }
}
