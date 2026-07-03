//
//  GchAnalyticsManager.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation

enum GchAnalyticsChannel: String, CaseIterable {
    case realtime
    case batch
    case deferred
    case priority
    case background
    case foreground
}

final class GchAnalyticsManager {
    static let shared = GchAnalyticsManager()
    private(set) var allowsCollection = true
    private(set) var userId: String?
    private let queue = DispatchQueue(label: "com.lookmedehook.analytics", qos: .utility)
    private var sequenceCounter = 0
    private var pendingEvents: [[String: Any]] = []
    private let flushThreshold = 20
    private init() {}

    func configure(userId: String?) { self.userId = userId }

    func applyCollectionPreference(_ active: Bool) { allowsCollection = active }

    func dispatch(_ event: GchTrackEvent, channel: GchAnalyticsChannel = .batch) {
        guard allowsCollection else { return }
        var payload = event.toDictionary()
        payload["channel"] = channel.rawValue
        payload["sequence"] = sequenceCounter
        sequenceCounter += 1
        queue.async { [weak self] in
            self?.pendingEvents.append(payload)
            if (self?.pendingEvents.count ?? 0) >= (self?.flushThreshold ?? 20) {
                self?.flushPendingEvents()
            }
        }
    }

    func flushPendingEvents() {
        let batch = pendingEvents
        pendingEvents.removeAll()
        GchEventReporter.shared.send(batch)
    }

    func report(channel: GchAnalyticsChannel) {
        let segment = pendingEvents.filter { ($0["channel"] as? String) == channel.rawValue }
        guard !segment.isEmpty else { return }
        GchEventReporter.shared.send(segment, tag: channel.rawValue)
    }
}
