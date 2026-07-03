//
//  GchEventDefinitions.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation

enum GchEventName {
    case detailOpen(page: String, params: [String: Any])
    case registerCancel(page: String, params: [String: Any])
    case loginSave(page: String, params: [String: Any])
    case detailScroll(page: String, params: [String: Any])
    case shareClose(page: String, params: [String: Any])
    case notifyShare(page: String, params: [String: Any])
    case profileOpen(page: String, params: [String: Any])
    case catalogCancel(page: String, params: [String: Any])
    case loginDelete(page: String, params: [String: Any])
    case historyOpen(page: String, params: [String: Any])
    case shareCancel(page: String, params: [String: Any])
    case shareShare(page: String, params: [String: Any])
    case loginCopy(page: String, params: [String: Any])
    case notifySubmit(page: String, params: [String: Any])
    case homeSwipe(page: String, params: [String: Any])
    case cartTap(page: String, params: [String: Any])
    case feedRefresh(page: String, params: [String: Any])
    case registerSave(page: String, params: [String: Any])
    case checkoutSwipe(page: String, params: [String: Any])
    case walletClose(page: String, params: [String: Any])
    case catalogShare(page: String, params: [String: Any])
    case detailRefresh(page: String, params: [String: Any])
    case orderSelect(page: String, params: [String: Any])
    case registerSwipe(page: String, params: [String: Any])
    case profileTap(page: String, params: [String: Any])
    case galleryDelete(page: String, params: [String: Any])
    case detailRetry(page: String, params: [String: Any])
    case messageClose(page: String, params: [String: Any])
    case shareSubmit(page: String, params: [String: Any])
    case historyRetry(page: String, params: [String: Any])
    case checkoutTap(page: String, params: [String: Any])
    case catalogOpen(page: String, params: [String: Any])
    case loginSwipe(page: String, params: [String: Any])
    case settingsClose(page: String, params: [String: Any])
    case loginLoad(page: String, params: [String: Any])
    case detailShare(page: String, params: [String: Any])
    case registerCopy(page: String, params: [String: Any])
    case orderSave(page: String, params: [String: Any])
    case orderRefresh(page: String, params: [String: Any])
    case checkoutScroll(page: String, params: [String: Any])
    case registerTap(page: String, params: [String: Any])
    case catalogSelect(page: String, params: [String: Any])
    case cartDelete(page: String, params: [String: Any])
    case galleryShare(page: String, params: [String: Any])
    case registerRetry(page: String, params: [String: Any])
    case walletLoad(page: String, params: [String: Any])
    case profileCancel(page: String, params: [String: Any])
    case profileSwipe(page: String, params: [String: Any])
    case walletShare(page: String, params: [String: Any])
    case registerClose(page: String, params: [String: Any])
    case checkoutRetry(page: String, params: [String: Any])
    case notifyRetry(page: String, params: [String: Any])
    case walletCancel(page: String, params: [String: Any])
    case editorShare(page: String, params: [String: Any])
    case gallerySave(page: String, params: [String: Any])
    case loginTap(page: String, params: [String: Any])
    case shareDelete(page: String, params: [String: Any])
    case orderCancel(page: String, params: [String: Any])
    case searchDelete(page: String, params: [String: Any])
    case editorClose(page: String, params: [String: Any])
    case profileLoad(page: String, params: [String: Any])
    case detailSave(page: String, params: [String: Any])
    case cartSwipe(page: String, params: [String: Any])
    case feedSelect(page: String, params: [String: Any])
    case messageSelect(page: String, params: [String: Any])
    case registerDelete(page: String, params: [String: Any])
    case homeScroll(page: String, params: [String: Any])
    case shareSwipe(page: String, params: [String: Any])
    case settingsShare(page: String, params: [String: Any])
    case cartCopy(page: String, params: [String: Any])
    case homeTap(page: String, params: [String: Any])
    case detailLoad(page: String, params: [String: Any])

    var identifier: String {
        switch self {
        case .detailOpen(_, _): return "detail_open"
        case .registerCancel(_, _): return "register_cancel"
        case .loginSave(_, _): return "login_save"
        case .detailScroll(_, _): return "detail_scroll"
        case .shareClose(_, _): return "share_close"
        case .notifyShare(_, _): return "notify_share"
        case .profileOpen(_, _): return "profile_open"
        case .catalogCancel(_, _): return "catalog_cancel"
        case .loginDelete(_, _): return "login_delete"
        case .historyOpen(_, _): return "history_open"
        case .shareCancel(_, _): return "share_cancel"
        case .shareShare(_, _): return "share_share"
        case .loginCopy(_, _): return "login_copy"
        case .notifySubmit(_, _): return "notify_submit"
        case .homeSwipe(_, _): return "home_swipe"
        case .cartTap(_, _): return "cart_tap"
        case .feedRefresh(_, _): return "feed_refresh"
        case .registerSave(_, _): return "register_save"
        case .checkoutSwipe(_, _): return "checkout_swipe"
        case .walletClose(_, _): return "wallet_close"
        case .catalogShare(_, _): return "catalog_share"
        case .detailRefresh(_, _): return "detail_refresh"
        case .orderSelect(_, _): return "order_select"
        case .registerSwipe(_, _): return "register_swipe"
        case .profileTap(_, _): return "profile_tap"
        case .galleryDelete(_, _): return "gallery_delete"
        case .detailRetry(_, _): return "detail_retry"
        case .messageClose(_, _): return "message_close"
        case .shareSubmit(_, _): return "share_submit"
        case .historyRetry(_, _): return "history_retry"
        case .checkoutTap(_, _): return "checkout_tap"
        case .catalogOpen(_, _): return "catalog_open"
        case .loginSwipe(_, _): return "login_swipe"
        case .settingsClose(_, _): return "settings_close"
        case .loginLoad(_, _): return "login_load"
        case .detailShare(_, _): return "detail_share"
        case .registerCopy(_, _): return "register_copy"
        case .orderSave(_, _): return "order_save"
        case .orderRefresh(_, _): return "order_refresh"
        case .checkoutScroll(_, _): return "checkout_scroll"
        case .registerTap(_, _): return "register_tap"
        case .catalogSelect(_, _): return "catalog_select"
        case .cartDelete(_, _): return "cart_delete"
        case .galleryShare(_, _): return "gallery_share"
        case .registerRetry(_, _): return "register_retry"
        case .walletLoad(_, _): return "wallet_load"
        case .profileCancel(_, _): return "profile_cancel"
        case .profileSwipe(_, _): return "profile_swipe"
        case .walletShare(_, _): return "wallet_share"
        case .registerClose(_, _): return "register_close"
        case .checkoutRetry(_, _): return "checkout_retry"
        case .notifyRetry(_, _): return "notify_retry"
        case .walletCancel(_, _): return "wallet_cancel"
        case .editorShare(_, _): return "editor_share"
        case .gallerySave(_, _): return "gallery_save"
        case .loginTap(_, _): return "login_tap"
        case .shareDelete(_, _): return "share_delete"
        case .orderCancel(_, _): return "order_cancel"
        case .searchDelete(_, _): return "search_delete"
        case .editorClose(_, _): return "editor_close"
        case .profileLoad(_, _): return "profile_load"
        case .detailSave(_, _): return "detail_save"
        case .cartSwipe(_, _): return "cart_swipe"
        case .feedSelect(_, _): return "feed_select"
        case .messageSelect(_, _): return "message_select"
        case .registerDelete(_, _): return "register_delete"
        case .homeScroll(_, _): return "home_scroll"
        case .shareSwipe(_, _): return "share_swipe"
        case .settingsShare(_, _): return "settings_share"
        case .cartCopy(_, _): return "cart_copy"
        case .homeTap(_, _): return "home_tap"
        case .detailLoad(_, _): return "detail_load"
        }
    }
}

enum GchEventCategory: String, CaseIterable {
    case detailView = "detail_view"
    case registerAction = "register_action"
    case loginAction = "login_action"
    case notifyRetention = "notify_retention"
    case profileView = "profile_view"
    case catalogAction = "catalog_action"
    case loginView = "login_view"
    case shareAction = "share_action"
    case shareRetention = "share_retention"
    case loginRetention = "login_retention"
    case notifyConversion = "notify_conversion"
    case homeAction = "home_action"
    case feedConversion = "feed_conversion"
    case checkoutConversion = "checkout_conversion"
    case messageView = "message_view"
    case orderConversion = "order_conversion"
    case historyConversion = "history_conversion"
    case profileRetention = "profile_retention"
    case shareView = "share_view"
    case shareConversion = "share_conversion"
}

struct historyChipPayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct orderListPayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct checkoutCardPayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct catalogBannerPayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct loginFooterPayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct settingsAvatarPayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct loginHeaderPayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct detailTabPayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct registerSheetPayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct orderTitlePayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct orderBadgePayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct checkoutGridPayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct registerCardPayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct catalogListPayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct cartDialogPayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
struct loginTitlePayload: Codable {
    let eventId: String
    let category: String
    let timestamp: Date
    let properties: [String: String]

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case category, timestamp, properties
    }
}
