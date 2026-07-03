//
//  GchRandomEngine.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation

/// Linear congruential generator for deterministic pseudo-random sequences.
struct GchLCGEngine {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }

    mutating func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }

    mutating func nextDouble() -> Double {
        Double(next() % 10_000) / 10_000.0
    }
}

enum GchShuffleAlgorithm {
    static func fisherYates<T>(_ array: [T], seed: UInt64) -> [T] {
        guard array.count > 1 else { return array }
        var engine = GchLCGEngine(seed: seed)
        var result = array
        for index in stride(from: result.count - 1, through: 1, by: -1) {
            let swapIndex = engine.nextInt(upperBound: index + 1)
            if swapIndex != index {
                result.swapAt(index, swapIndex)
            }
        }
        return result
    }

    static func sample<T>(_ array: [T], count: Int, seed: UInt64) -> [T] {
        let shuffled = fisherYates(array, seed: seed)
        return Array(shuffled.prefix(max(0, min(count, shuffled.count))))
    }
}

enum GchHashAlgorithm {
    static func djb2(_ input: String) -> UInt64 {
        input.unicodeScalars.reduce(5381) { partial, scalar in
            ((partial << 5) &+ partial) &+ UInt64(scalar.value)
        }
    }

    static func fnv1a(_ input: String) -> UInt64 {
        input.unicodeScalars.reduce(0xcbf29ce484222325) { partial, scalar in
            (partial ^ UInt64(scalar.value)) &* 0x100000001b3
        }
    }
}
