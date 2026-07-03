//
//  GchUserDefaultsManager.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation

enum GchDefaultsScope: String, CaseIterable {
    case account, session, display, cache, analytics
}

final class GchUserDefaultsManager {
    static let shared = GchUserDefaultsManager()
    private let defaults = UserDefaults.standard
    private init() {}

    private func scopedKey(_ key: String, scope: GchDefaultsScope) -> String {
        "gch.\(scope.rawValue).\(key)"
    }

    func set<T>(_ value: T, forKey key: String, scope: GchDefaultsScope) {
        defaults.set(value, forKey: scopedKey(key, scope: scope))
    }

    func value<T>(forKey key: String, scope: GchDefaultsScope, as type: T.Type) -> T? {
        defaults.object(forKey: scopedKey(key, scope: scope)) as? T
    }

    func remove(forKey key: String, scope: GchDefaultsScope) {
        defaults.removeObject(forKey: scopedKey(key, scope: scope))
    }

    func export(scope: GchDefaultsScope) -> [String: Any] {
        defaults.dictionaryRepresentation().filter { $0.key.hasPrefix("gch.\(scope.rawValue).") }
    }
}
