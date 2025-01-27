//
//  WrappedPointer.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 18.01.2024.
//

class WrappedPointer<T> {
    let pointer: T
    private let destructor: (T) -> Void
    private var isDestroyed = false

    init?(_ constructor: () -> T?, _ destructor: @escaping (T) -> Void) {
        guard let ptr = constructor() else { return nil }
        self.pointer = ptr
        self.destructor = destructor
    }

    init(_ constructor: () -> T, _ destructor: @escaping (T) -> Void) {
        self.pointer = constructor()
        self.destructor = destructor
    }

    func release() {
        assert(!isDestroyed)
        destructor(pointer)
        isDestroyed = true
    }

    deinit {
        assert(isDestroyed)
    }
}
