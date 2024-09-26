//
//  ThreadSafeDictionary.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 26.09.2024.
//

import Foundation


class ThreadSafeDictionary<V: Hashable, T>: Collection {
    private var dictionary: [V: T]
    private let concurrentQueue: DispatchQueue

    var startIndex: Dictionary<V, T>.Index {
        self.concurrentQueue.sync {
            return self.dictionary.startIndex
        }
    }

    var endIndex: Dictionary<V, T>.Index {
        self.concurrentQueue.sync {
            return self.dictionary.endIndex
        }
    }

    init(dict: [V: T] = [V: T](), label: String = "Dictionary Barrier Queue") {
        self.concurrentQueue = DispatchQueue(label: label, attributes: .concurrent)
        self.dictionary = dict
    }

    func index(after i: Dictionary<V, T>.Index) -> Dictionary<V, T>.Index {
        self.concurrentQueue.sync {
            return self.dictionary.index(after: i)
        }
    }

    subscript(key: V) -> T? {
        get {
            self.concurrentQueue.sync {
                return self.dictionary[key]
            }
        }
        set(newValue) {
            self.concurrentQueue.sync(flags: .barrier) { [weak self] in
                self?.dictionary[key] = newValue
            }
        }
    }

    subscript(index: Dictionary<V, T>.Index) -> Dictionary<V, T>.Element {
        self.concurrentQueue.sync {
            return self.dictionary[index]
        }
    }
}

extension ThreadSafeDictionary {
    var keys: Dictionary<V, T>.Keys {
        self.concurrentQueue.sync {
            return self.dictionary.keys
        }
    }

    var values: Dictionary<V, T>.Values {
        self.concurrentQueue.sync {
            return self.dictionary.values
        }
    }

    func filter(_ isIncluded: (Dictionary<V, T>.Element) throws -> Bool) rethrows -> ThreadSafeDictionary<V, T> {
        try self.concurrentQueue.sync {
            return try ThreadSafeDictionary(dict: self.dictionary.filter { try isIncluded($0) })
        }
    }

    @discardableResult
    func removeValue(forKey key: V) -> T? {
        self.concurrentQueue.sync(flags: .barrier) {
            return self.dictionary.removeValue(forKey: key)
        }
    }

    @discardableResult
    func updateValue(_ value: T, forKey key: V) -> T? {
        self.concurrentQueue.sync(flags: .barrier) {
            return self.dictionary.updateValue(value, forKey: key)
        }
    }

    func removeAll() {
        self.concurrentQueue.sync(flags: .barrier) {
            self.dictionary.removeAll()
        }
    }
}
