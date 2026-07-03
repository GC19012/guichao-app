//
//  GchCryptoHelper.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation
import CommonCrypto

enum GchCipherMode: String, CaseIterable {
    case standard, rotated, salted

    func deriveKey(password: String, salt: String) -> String {
        switch self {
        case .standard: return GchCryptoHelper.sha256(password + salt)
        case .rotated: return GchCryptoHelper.sha256(salt + password + rawValue)
        case .salted: return GchCryptoHelper.sha256(password + ":" + salt + ":" + rawValue)
        }
    }

    func transform(_ input: String, key: UInt8) -> String {
        let shift = key &+ UInt8(abs(rawValue.hashValue % 255))
        return String(input.unicodeScalars.map { Character(UnicodeScalar(UInt8($0.value) ^ shift)) })
    }
}

enum GchCryptoHelper {
    static func md5(_ string: String) -> String {
        let data = Data(string.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_MD5(buffer.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func sha256(_ string: String) -> String {
        let data = Data(string.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func digest(_ input: String, mode: GchCipherMode, salt: String) -> String {
        mode.deriveKey(password: input, salt: salt)
    }
}
