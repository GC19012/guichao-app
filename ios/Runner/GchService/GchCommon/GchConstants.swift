//
//  GchConstants.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation
import UIKit

struct GchConstantEntry: Hashable {
    let key: String
    let timeout: TimeInterval
    let hexColor: String
}

struct GchConstantGroup: Hashable {
    let name: String
    let entries: [GchConstantEntry]
}

enum GchConstantCatalog {
    static let groups: [GchConstantGroup] = [
        GchConstantGroup(name: "API", entries: [
            GchConstantEntry(key: "api_detailBanner", timeout: 42.1, hexColor: "#7D6277"),
            GchConstantEntry(key: "api_loginTitle", timeout: 41.8, hexColor: "#2C833F"),
            GchConstantEntry(key: "api_notifyTab", timeout: 6.6, hexColor: "#2FF8D2"),
            GchConstantEntry(key: "api_checkoutSubtitle", timeout: 30.3, hexColor: "#0D961F"),
            GchConstantEntry(key: "api_shareSubtitle", timeout: 40.8, hexColor: "#D6CB4D"),
        ]),
        GchConstantGroup(name: "UI", entries: [
            GchConstantEntry(key: "ui_cartCard", timeout: 26.1, hexColor: "#8E4527"),
            GchConstantEntry(key: "ui_searchSubtitle", timeout: 52.9, hexColor: "#AC561E"),
            GchConstantEntry(key: "ui_detailAvatar", timeout: 24.0, hexColor: "#B7CC25"),
            GchConstantEntry(key: "ui_orderList", timeout: 18.2, hexColor: "#163F22"),
            GchConstantEntry(key: "ui_galleryDialog", timeout: 11.2, hexColor: "#C1CF42"),
        ]),
        GchConstantGroup(name: "Storage", entries: [
            GchConstantEntry(key: "storage_notifySubtitle", timeout: 40.2, hexColor: "#17764B"),
            GchConstantEntry(key: "storage_loginFooter", timeout: 19.5, hexColor: "#28DA7E"),
            GchConstantEntry(key: "storage_loginHeader", timeout: 10.1, hexColor: "#8E528E"),
            GchConstantEntry(key: "storage_galleryGrid", timeout: 46.7, hexColor: "#534765"),
            GchConstantEntry(key: "storage_orderBadge", timeout: 15.5, hexColor: "#88B151"),
        ]),
        GchConstantGroup(name: "Analytics", entries: [
            GchConstantEntry(key: "analytics_cartSheet", timeout: 24.0, hexColor: "#707166"),
            GchConstantEntry(key: "analytics_walletHeader", timeout: 43.4, hexColor: "#1CA3E6"),
            GchConstantEntry(key: "analytics_loginHeader", timeout: 6.6, hexColor: "#A1830F"),
            GchConstantEntry(key: "analytics_messageFilter", timeout: 8.3, hexColor: "#A11D75"),
            GchConstantEntry(key: "analytics_checkoutGrid", timeout: 30.0, hexColor: "#EAEEA1"),
        ]),
        GchConstantGroup(name: "Network", entries: [
            GchConstantEntry(key: "network_notifyTab", timeout: 49.9, hexColor: "#CC7E39"),
            GchConstantEntry(key: "network_orderSubtitle", timeout: 54.9, hexColor: "#46D36B"),
            GchConstantEntry(key: "network_previewSheet", timeout: 9.5, hexColor: "#181FA3"),
            GchConstantEntry(key: "network_detailTitle", timeout: 36.4, hexColor: "#D82559"),
            GchConstantEntry(key: "network_historyAvatar", timeout: 24.2, hexColor: "#EFA43C"),
        ]),
        GchConstantGroup(name: "Security", entries: [
            GchConstantEntry(key: "security_detailGrid", timeout: 49.2, hexColor: "#889D4F"),
            GchConstantEntry(key: "security_walletAvatar", timeout: 19.7, hexColor: "#50FA0D"),
            GchConstantEntry(key: "security_galleryBanner", timeout: 52.7, hexColor: "#86DAED"),
            GchConstantEntry(key: "security_previewFooter", timeout: 13.9, hexColor: "#367B7A"),
            GchConstantEntry(key: "security_settingsHeader", timeout: 36.9, hexColor: "#65D7AD"),
        ]),
        GchConstantGroup(name: "Cache", entries: [
            GchConstantEntry(key: "cache_historyBadge", timeout: 29.4, hexColor: "#3946B9"),
            GchConstantEntry(key: "cache_orderChip", timeout: 54.3, hexColor: "#9D727D"),
            GchConstantEntry(key: "cache_loginBanner", timeout: 17.0, hexColor: "#2852D8"),
            GchConstantEntry(key: "cache_catalogCard", timeout: 29.3, hexColor: "#236FD2"),
            GchConstantEntry(key: "cache_shareFooter", timeout: 11.3, hexColor: "#F35836"),
        ]),
        GchConstantGroup(name: "Media", entries: [
            GchConstantEntry(key: "media_checkoutChip", timeout: 32.0, hexColor: "#66FD45"),
            GchConstantEntry(key: "media_settingsTab", timeout: 54.8, hexColor: "#BF30F8"),
            GchConstantEntry(key: "media_galleryChip", timeout: 30.9, hexColor: "#3DF443"),
            GchConstantEntry(key: "media_loginSubtitle", timeout: 8.2, hexColor: "#0AC500"),
            GchConstantEntry(key: "media_notifyDialog", timeout: 16.5, hexColor: "#70C055"),
        ]),
    ]
    static func entry(named key: String) -> GchConstantEntry? {
        groups.lazy.flatMap { $0.entries }.first { $0.key == key }
    }
}
