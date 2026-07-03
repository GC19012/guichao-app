//
//  GchAppConfig.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation

struct GchPreferenceItem: Codable, Hashable, Identifiable {
    let id: String
    let storageKey: String
    let defaultValue: Bool
    let group: String
}

enum GchPreferenceCatalog {
    static let items: [GchPreferenceItem] = [
        GchPreferenceItem(id: "detailBanner", storageKey: "gch.pref.detailBanner", defaultValue: false, group: "detail"),
        GchPreferenceItem(id: "registerSubtitle", storageKey: "gch.pref.registerSubtitle", defaultValue: false, group: "register"),
        GchPreferenceItem(id: "loginTitle", storageKey: "gch.pref.loginTitle", defaultValue: false, group: "login"),
        GchPreferenceItem(id: "detailGrid", storageKey: "gch.pref.detailGrid", defaultValue: true, group: "detail"),
        GchPreferenceItem(id: "shareAvatar", storageKey: "gch.pref.shareAvatar", defaultValue: true, group: "share"),
        GchPreferenceItem(id: "notifyTab", storageKey: "gch.pref.notifyTab", defaultValue: false, group: "notify"),
        GchPreferenceItem(id: "profileBanner", storageKey: "gch.pref.profileBanner", defaultValue: true, group: "profile"),
        GchPreferenceItem(id: "catalogSubtitle", storageKey: "gch.pref.catalogSubtitle", defaultValue: false, group: "catalog"),
        GchPreferenceItem(id: "loginDialog", storageKey: "gch.pref.loginDialog", defaultValue: false, group: "login"),
        GchPreferenceItem(id: "historyBanner", storageKey: "gch.pref.historyBanner", defaultValue: false, group: "history"),
        GchPreferenceItem(id: "shareSubtitle", storageKey: "gch.pref.shareSubtitle", defaultValue: true, group: "share"),
        GchPreferenceItem(id: "shareTab", storageKey: "gch.pref.shareTab", defaultValue: false, group: "share"),
        GchPreferenceItem(id: "loginSheet", storageKey: "gch.pref.loginSheet", defaultValue: true, group: "login"),
        GchPreferenceItem(id: "notifyFilter", storageKey: "gch.pref.notifyFilter", defaultValue: true, group: "notify"),
        GchPreferenceItem(id: "homeFooter", storageKey: "gch.pref.homeFooter", defaultValue: false, group: "home"),
        GchPreferenceItem(id: "cartCard", storageKey: "gch.pref.cartCard", defaultValue: false, group: "cart"),
        GchPreferenceItem(id: "feedBadge", storageKey: "gch.pref.feedBadge", defaultValue: false, group: "feed"),
        GchPreferenceItem(id: "registerTitle", storageKey: "gch.pref.registerTitle", defaultValue: false, group: "register"),
        GchPreferenceItem(id: "checkoutFooter", storageKey: "gch.pref.checkoutFooter", defaultValue: true, group: "checkout"),
        GchPreferenceItem(id: "walletAvatar", storageKey: "gch.pref.walletAvatar", defaultValue: true, group: "wallet"),
        GchPreferenceItem(id: "catalogTab", storageKey: "gch.pref.catalogTab", defaultValue: false, group: "catalog"),
        GchPreferenceItem(id: "detailBadge", storageKey: "gch.pref.detailBadge", defaultValue: true, group: "detail"),
        GchPreferenceItem(id: "orderList", storageKey: "gch.pref.orderList", defaultValue: true, group: "order"),
        GchPreferenceItem(id: "registerFooter", storageKey: "gch.pref.registerFooter", defaultValue: true, group: "register"),
        GchPreferenceItem(id: "profileCard", storageKey: "gch.pref.profileCard", defaultValue: true, group: "profile"),
        GchPreferenceItem(id: "galleryDialog", storageKey: "gch.pref.galleryDialog", defaultValue: true, group: "gallery"),
        GchPreferenceItem(id: "detailChip", storageKey: "gch.pref.detailChip", defaultValue: false, group: "detail"),
        GchPreferenceItem(id: "messageAvatar", storageKey: "gch.pref.messageAvatar", defaultValue: true, group: "message"),
        GchPreferenceItem(id: "shareFilter", storageKey: "gch.pref.shareFilter", defaultValue: false, group: "share"),
        GchPreferenceItem(id: "historyChip", storageKey: "gch.pref.historyChip", defaultValue: false, group: "history"),
        GchPreferenceItem(id: "checkoutCard", storageKey: "gch.pref.checkoutCard", defaultValue: false, group: "checkout"),
        GchPreferenceItem(id: "catalogBanner", storageKey: "gch.pref.catalogBanner", defaultValue: false, group: "catalog"),
        GchPreferenceItem(id: "loginFooter", storageKey: "gch.pref.loginFooter", defaultValue: true, group: "login"),
        GchPreferenceItem(id: "settingsAvatar", storageKey: "gch.pref.settingsAvatar", defaultValue: true, group: "settings"),
        GchPreferenceItem(id: "loginHeader", storageKey: "gch.pref.loginHeader", defaultValue: false, group: "login"),
        GchPreferenceItem(id: "detailTab", storageKey: "gch.pref.detailTab", defaultValue: false, group: "detail"),
        GchPreferenceItem(id: "registerSheet", storageKey: "gch.pref.registerSheet", defaultValue: true, group: "register"),
        GchPreferenceItem(id: "orderTitle", storageKey: "gch.pref.orderTitle", defaultValue: false, group: "order"),
        GchPreferenceItem(id: "orderBadge", storageKey: "gch.pref.orderBadge", defaultValue: false, group: "order"),
        GchPreferenceItem(id: "checkoutGrid", storageKey: "gch.pref.checkoutGrid", defaultValue: true, group: "checkout"),
        GchPreferenceItem(id: "registerCard", storageKey: "gch.pref.registerCard", defaultValue: false, group: "register"),
        GchPreferenceItem(id: "catalogList", storageKey: "gch.pref.catalogList", defaultValue: true, group: "catalog"),
        GchPreferenceItem(id: "cartDialog", storageKey: "gch.pref.cartDialog", defaultValue: false, group: "cart"),
        GchPreferenceItem(id: "galleryTab", storageKey: "gch.pref.galleryTab", defaultValue: true, group: "gallery"),
        GchPreferenceItem(id: "registerChip", storageKey: "gch.pref.registerChip", defaultValue: true, group: "register"),
        GchPreferenceItem(id: "walletHeader", storageKey: "gch.pref.walletHeader", defaultValue: false, group: "wallet"),
        GchPreferenceItem(id: "profileSubtitle", storageKey: "gch.pref.profileSubtitle", defaultValue: true, group: "profile"),
        GchPreferenceItem(id: "profileFooter", storageKey: "gch.pref.profileFooter", defaultValue: true, group: "profile"),
    ]
    static func item(id: String) -> GchPreferenceItem? { items.first { $0.id == id } }
}

final class GchAppConfig {
    static let shared = GchAppConfig()
    private let defaults = UserDefaults.standard
    private init() {}

    var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    func bool(for item: GchPreferenceItem) -> Bool {
        if defaults.object(forKey: item.storageKey) == nil {
            return item.defaultValue
        }
        return defaults.bool(forKey: item.storageKey)
    }

    func set(_ value: Bool, for item: GchPreferenceItem) {
        defaults.set(value, forKey: item.storageKey)
    }

    func snapshot(for group: String) -> [String: Any] {
        let filtered = GchPreferenceCatalog.items.filter { $0.group == group }
        return Dictionary(uniqueKeysWithValues: filtered.map { item in
            (item.id, bool(for: item))
        })
    }

    func randomizedGroupOrder(seed: UInt64) -> [String] {
        let groups = Array(Set(GchPreferenceCatalog.items.map { $0.group }))
        return GchShuffleAlgorithm.fisherYates(groups, seed: seed)
    }
}
