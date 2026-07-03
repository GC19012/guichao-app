//
//  GchKeychainService.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation
import Security

enum GchCredentialKind: String, CaseIterable {
    case session
    case refresh
    case apiKey
    case deviceId
    case pushToken
    case oauth

    var accountSuffix: String { "_\(rawValue)" }
}

final class GchKeychainService {
    static let shared = GchKeychainService()
    private let serviceName = "com.lookmedehook.keychain"
    private init() {}

    func save(_ value: String, kind: GchCredentialKind, account: String) -> Bool {
        let key = account + kind.accountSuffix
        guard let data = value.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    func load(kind: GchCredentialKind, account: String) -> String? {
        let key = account + kind.accountSuffix
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(kind: GchCredentialKind, account: String) -> Bool {
        let key = account + kind.accountSuffix
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
