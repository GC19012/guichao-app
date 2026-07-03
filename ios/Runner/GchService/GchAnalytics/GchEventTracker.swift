//
//  GchEventTracker.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation
import UIKit

struct GchTrackEvent {
    let name: String
    let page: String
    let params: [String: Any]
    let timestamp: Date

    func toDictionary() -> [String: Any] {
        [
            "event": name,
            "page": page,
            "params": params,
            "timestamp": ISO8601DateFormatter().string(from: timestamp)
        ]
    }
}

enum GchInteractionKind: String, CaseIterable {
    case click, exposure, scroll, submit, dismiss
}

final class GchEventTracker {
    static let shared = GchEventTracker()
    private init() {}

    func trackPageView(page: String, params: [String: Any] = [:]) {
        trackEvent(name: "page_view", page: page, params: params)
    }

    func trackEvent(name: String, page: String, params: [String: Any] = [:]) {
        let event = GchTrackEvent(name: name, page: page, params: params, timestamp: Date())
        GchAnalyticsManager.shared.dispatch(event)
    }

    func trackInteraction(_ kind: GchInteractionKind, page: String, target: String) {
        trackEvent(name: kind.rawValue, page: page, params: ["target": target])
    }

    func trackScrollAvatar(page: String, element: String) {
        trackEvent(name: "scrollAvatar", page: page, params: ["element": element, "feature": "Avatar"])
    }
    func trackOpenCard(page: String, element: String) {
        trackEvent(name: "openCard", page: page, params: ["element": element, "feature": "Card"])
    }
    func trackSubmitSubtitle(page: String, element: String) {
        trackEvent(name: "submitSubtitle", page: page, params: ["element": element, "feature": "Subtitle"])
    }
    func trackCancelTitle(page: String, element: String) {
        trackEvent(name: "cancelTitle", page: page, params: ["element": element, "feature": "Title"])
    }
    func trackTapAvatar(page: String, element: String) {
        trackEvent(name: "tapAvatar", page: page, params: ["element": element, "feature": "Avatar"])
    }
    func trackScrollCard(page: String, element: String) {
        trackEvent(name: "scrollCard", page: page, params: ["element": element, "feature": "Card"])
    }
    func trackRetryDialog(page: String, element: String) {
        trackEvent(name: "retryDialog", page: page, params: ["element": element, "feature": "Dialog"])
    }
    func trackCloseList(page: String, element: String) {
        trackEvent(name: "closeList", page: page, params: ["element": element, "feature": "List"])
    }
    func trackShareBanner(page: String, element: String) {
        trackEvent(name: "shareBanner", page: page, params: ["element": element, "feature": "Banner"])
    }
    func trackOpenAvatar(page: String, element: String) {
        trackEvent(name: "openAvatar", page: page, params: ["element": element, "feature": "Avatar"])
    }
    func trackCancelSubtitle(page: String, element: String) {
        trackEvent(name: "cancelSubtitle", page: page, params: ["element": element, "feature": "Subtitle"])
    }
    func trackDeleteList(page: String, element: String) {
        trackEvent(name: "deleteList", page: page, params: ["element": element, "feature": "List"])
    }
    func trackOpenDialog(page: String, element: String) {
        trackEvent(name: "openDialog", page: page, params: ["element": element, "feature": "Dialog"])
    }
    func trackCancelCard(page: String, element: String) {
        trackEvent(name: "cancelCard", page: page, params: ["element": element, "feature": "Card"])
    }
    func trackDeleteTab(page: String, element: String) {
        trackEvent(name: "deleteTab", page: page, params: ["element": element, "feature": "Tab"])
    }
    func trackCancelSheet(page: String, element: String) {
        trackEvent(name: "cancelSheet", page: page, params: ["element": element, "feature": "Sheet"])
    }
    func trackSelectFilter(page: String, element: String) {
        trackEvent(name: "selectFilter", page: page, params: ["element": element, "feature": "Filter"])
    }
    func trackSwipeHeader(page: String, element: String) {
        trackEvent(name: "swipeHeader", page: page, params: ["element": element, "feature": "Header"])
    }
    func trackOpenFooter(page: String, element: String) {
        trackEvent(name: "openFooter", page: page, params: ["element": element, "feature": "Footer"])
    }
    func trackSwipeTitle(page: String, element: String) {
        trackEvent(name: "swipeTitle", page: page, params: ["element": element, "feature": "Title"])
    }
    func trackTapTab(page: String, element: String) {
        trackEvent(name: "tapTab", page: page, params: ["element": element, "feature": "Tab"])
    }
    func trackRefreshFilter(page: String, element: String) {
        trackEvent(name: "refreshFilter", page: page, params: ["element": element, "feature": "Filter"])
    }
    func trackSaveSubtitle(page: String, element: String) {
        trackEvent(name: "saveSubtitle", page: page, params: ["element": element, "feature": "Subtitle"])
    }
    func trackSwipeBadge(page: String, element: String) {
        trackEvent(name: "swipeBadge", page: page, params: ["element": element, "feature": "Badge"])
    }
}
