//
//  WrappedPointer.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 18.01.2024.
//

class WrappedPointer<T> {
    let pointer: T
    private let destructor: (T) -> Void

    init(ptr: T, _ destructor: @escaping (T) -> Void) {
        self.pointer = ptr
        self.destructor = destructor
    }

    deinit {
        destructor(pointer)
    }
}
