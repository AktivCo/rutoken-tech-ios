//
//  WrappedPointer.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 18.01.2024.
//

class WrappedPointer {
    let pointer: OpaquePointer
    private let destructor: (OpaquePointer) -> Void

    init(ptr: OpaquePointer, _ destructor: @escaping (OpaquePointer) -> Void) {
        self.pointer = ptr
        self.destructor = destructor
    }

    deinit {
        destructor(pointer)
    }
}
