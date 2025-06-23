//
//  Sequence+asyncMap.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 23.06.2025.
//


extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}
