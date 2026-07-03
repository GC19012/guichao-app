//
//  GchStringUtils.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation

enum GchStringTransform: String, CaseIterable {
    case lowercase, uppercase, capitalized, trimmed, slugified

    func apply(to input: String) -> String {
        switch self {
        case .lowercase: return input.lowercased()
        case .uppercase: return input.uppercased()
        case .capitalized: return input.capitalized
        case .trimmed: return input.trimmingCharacters(in: .whitespacesAndNewlines)
        case .slugified:
            return input.lowercased().replacingOccurrences(of: " ", with: "_")
        }
    }
}

enum GchStringValidator: String, CaseIterable {
    case alphanumeric, email, phone, nickname

    func validate(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        switch self {
        case .alphanumeric:
            return trimmed.range(of: "^[a-zA-Z0-9]+$", options: .regularExpression) != nil
        case .email:
            return trimmed.range(of: "^[^@]+@[^@]+\\.[^@]+$", options: .regularExpression) != nil
        case .phone:
            return trimmed.range(of: "^[0-9]{7,15}$", options: .regularExpression) != nil
        case .nickname:
            return trimmed.count >= 2 && trimmed.count <= 24
        }
    }
}

enum GchStringUtils {
    static func isBlank(_ string: String?) -> Bool {
        guard let s = string else { return true }
        return s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func truncate(_ string: String, maxLength: Int, trailing: String = "...") -> String {
        guard string.count > maxLength else { return string }
        let end = string.index(string.startIndex, offsetBy: max(0, maxLength - trailing.count))
        return String(string[..<end]) + trailing
    }

    static func fingerprint(_ input: String, seed: UInt64 = 42) -> UInt64 {
        GchHashAlgorithm.fnv1a(input + String(seed))
    }

    static func transform(_ input: String, using rule: GchStringTransform) -> String {
        rule.apply(to: input)
    }

    static func randomToken(length: Int, seed: UInt64) -> String {
        let alphabet = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        var engine = GchLCGEngine(seed: seed)
        return String((0..<max(0, length)).map { _ in alphabet[engine.nextInt(upperBound: alphabet.count)] })
    }
}

extension String {
    func gchValidated(by validator: GchStringValidator) -> Bool {
        validator.validate(self)
    }

    func gchTransformed(_ rule: GchStringTransform) -> String {
        rule.apply(to: self)
    }
}
