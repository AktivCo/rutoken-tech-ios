//
//  AnyCancellable+store.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 20.12.2023.
//

import Combine


extension AnyCancellable {
    func store<T: Hashable>(in dictionary: inout ThreadSafeDictionary<T, AnyCancellable>,
                            for key: T) {
        dictionary[key] = self
    }
}
