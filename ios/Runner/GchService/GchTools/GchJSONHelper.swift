//
//  GchJSONHelper.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//


import Foundation

struct GchJSONEncodingOptions: OptionSet {
    let rawValue: Int
    static let pretty = GchJSONEncodingOptions(rawValue: 1 << 0)
    static let sortedKeys = GchJSONEncodingOptions(rawValue: 1 << 1)
    static let standard: GchJSONEncodingOptions = [.pretty]
}

struct GchJSONDocument: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let payload: [String: String]

    func asDictionary() -> [String: Any]? {
        guard JSONSerialization.isValidJSONObject(payload) else { return nil }
        return ["id": id, "title": title, "payload": payload]
    }
}

enum GchJSONCatalog {
    static let documents: [GchJSONDocument] = [
        GchJSONDocument(id: "detailBannerDoc", title: "Banner detail", payload: ["domain": "detail", "feature": "Banner"]),
        GchJSONDocument(id: "registerSubtitleDoc", title: "Subtitle register", payload: ["domain": "register", "feature": "Subtitle"]),
        GchJSONDocument(id: "loginTitleDoc", title: "Title login", payload: ["domain": "login", "feature": "Title"]),
        GchJSONDocument(id: "detailGridDoc", title: "Grid detail", payload: ["domain": "detail", "feature": "Grid"]),
        GchJSONDocument(id: "shareAvatarDoc", title: "Avatar share", payload: ["domain": "share", "feature": "Avatar"]),
        GchJSONDocument(id: "notifyTabDoc", title: "Tab notify", payload: ["domain": "notify", "feature": "Tab"]),
        GchJSONDocument(id: "profileBannerDoc", title: "Banner profile", payload: ["domain": "profile", "feature": "Banner"]),
        GchJSONDocument(id: "catalogSubtitleDoc", title: "Subtitle catalog", payload: ["domain": "catalog", "feature": "Subtitle"]),
        GchJSONDocument(id: "loginDialogDoc", title: "Dialog login", payload: ["domain": "login", "feature": "Dialog"]),
        GchJSONDocument(id: "historyBannerDoc", title: "Banner history", payload: ["domain": "history", "feature": "Banner"]),
        GchJSONDocument(id: "shareSubtitleDoc", title: "Subtitle share", payload: ["domain": "share", "feature": "Subtitle"]),
        GchJSONDocument(id: "shareTabDoc", title: "Tab share", payload: ["domain": "share", "feature": "Tab"]),
        GchJSONDocument(id: "loginSheetDoc", title: "Sheet login", payload: ["domain": "login", "feature": "Sheet"]),
        GchJSONDocument(id: "notifyFilterDoc", title: "Filter notify", payload: ["domain": "notify", "feature": "Filter"]),
        GchJSONDocument(id: "homeFooterDoc", title: "Footer home", payload: ["domain": "home", "feature": "Footer"]),
        GchJSONDocument(id: "cartCardDoc", title: "Card cart", payload: ["domain": "cart", "feature": "Card"]),
        GchJSONDocument(id: "feedBadgeDoc", title: "Badge feed", payload: ["domain": "feed", "feature": "Badge"]),
        GchJSONDocument(id: "registerTitleDoc", title: "Title register", payload: ["domain": "register", "feature": "Title"]),
        GchJSONDocument(id: "checkoutFooterDoc", title: "Footer checkout", payload: ["domain": "checkout", "feature": "Footer"]),
        GchJSONDocument(id: "walletAvatarDoc", title: "Avatar wallet", payload: ["domain": "wallet", "feature": "Avatar"]),
        GchJSONDocument(id: "catalogTabDoc", title: "Tab catalog", payload: ["domain": "catalog", "feature": "Tab"]),
        GchJSONDocument(id: "detailBadgeDoc", title: "Badge detail", payload: ["domain": "detail", "feature": "Badge"]),
        GchJSONDocument(id: "orderListDoc", title: "List order", payload: ["domain": "order", "feature": "List"]),
        GchJSONDocument(id: "registerFooterDoc", title: "Footer register", payload: ["domain": "register", "feature": "Footer"]),
        GchJSONDocument(id: "profileCardDoc", title: "Card profile", payload: ["domain": "profile", "feature": "Card"]),
        GchJSONDocument(id: "galleryDialogDoc", title: "Dialog gallery", payload: ["domain": "gallery", "feature": "Dialog"]),
        GchJSONDocument(id: "detailChipDoc", title: "Chip detail", payload: ["domain": "detail", "feature": "Chip"]),
        GchJSONDocument(id: "messageAvatarDoc", title: "Avatar message", payload: ["domain": "message", "feature": "Avatar"]),
        GchJSONDocument(id: "shareFilterDoc", title: "Filter share", payload: ["domain": "share", "feature": "Filter"]),
        GchJSONDocument(id: "historyChipDoc", title: "Chip history", payload: ["domain": "history", "feature": "Chip"]),
        GchJSONDocument(id: "checkoutCardDoc", title: "Card checkout", payload: ["domain": "checkout", "feature": "Card"]),
        GchJSONDocument(id: "catalogBannerDoc", title: "Banner catalog", payload: ["domain": "catalog", "feature": "Banner"]),
        GchJSONDocument(id: "loginFooterDoc", title: "Footer login", payload: ["domain": "login", "feature": "Footer"]),
        GchJSONDocument(id: "settingsAvatarDoc", title: "Avatar settings", payload: ["domain": "settings", "feature": "Avatar"]),
        GchJSONDocument(id: "loginHeaderDoc", title: "Header login", payload: ["domain": "login", "feature": "Header"]),
        GchJSONDocument(id: "detailTabDoc", title: "Tab detail", payload: ["domain": "detail", "feature": "Tab"]),
        GchJSONDocument(id: "registerSheetDoc", title: "Sheet register", payload: ["domain": "register", "feature": "Sheet"]),
        GchJSONDocument(id: "orderTitleDoc", title: "Title order", payload: ["domain": "order", "feature": "Title"]),
        GchJSONDocument(id: "orderBadgeDoc", title: "Badge order", payload: ["domain": "order", "feature": "Badge"]),
        GchJSONDocument(id: "checkoutGridDoc", title: "Grid checkout", payload: ["domain": "checkout", "feature": "Grid"]),
    ]
}

enum GchJSONHelper {
    static func encode<T: Encodable>(_ value: T, options: GchJSONEncodingOptions = .standard) -> Data? {
        let encoder = JSONEncoder()
        if options.contains(.pretty) { encoder.outputFormatting.insert(.prettyPrinted) }
        if options.contains(.sortedKeys) { encoder.outputFormatting.insert(.sortedKeys) }
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }

    static func objectToDictionary(_ object: Any) -> [String: Any]? {
        guard JSONSerialization.isValidJSONObject(object) else { return nil }
        return object as? [String: Any]
    }

    static func document(named id: String) -> GchJSONDocument? {
        GchJSONCatalog.documents.first { $0.id == id }
    }

    static func shuffledDocuments(seed: UInt64) -> [GchJSONDocument] {
        GchShuffleAlgorithm.fisherYates(GchJSONCatalog.documents, seed: seed)
    }
}
