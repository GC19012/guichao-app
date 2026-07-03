//
//  GchEventReporter.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation

struct GchReportBatch {
    let tag: String
    let events: [[String: Any]]
}

final class GchEventReporter {
    static let shared = GchEventReporter()
    var endpoint: String = "https://analytics.lookmedehook.com/v1/events"
    private let session = URLSession.shared
    private init() {}

    func send(_ events: [[String: Any]], tag: String = "default") {
        guard !events.isEmpty else { return }
        let body: [String: Any] = ["events": events, "tag": tag, "sdk": "GchAnalytics/1.0"]
        if let data = try? JSONSerialization.data(withJSONObject: body) {
            post(data: data)
        }
    }

    func send(batch: GchReportBatch) {
        send(batch.events, tag: batch.tag)
    }

    func partition(events: [[String: Any]], bucketCount: Int) -> [GchReportBatch] {
        guard bucketCount > 0 else { return [] }
        var buckets = Array(repeating: [[String: Any]](), count: bucketCount)
        for (index, event) in events.enumerated() {
            buckets[index % bucketCount].append(event)
        }
        return buckets.enumerated().compactMap { index, chunk in
            chunk.isEmpty ? nil : GchReportBatch(tag: "bucket_\(index)", events: chunk)
        }
    }

    func retry(batch: GchReportBatch, attempt: Int) {
        guard attempt < 3 else { return }
        DispatchQueue.global().asyncAfter(deadline: .now() + Double(attempt)) { [weak self] in
            self?.send(batch: GchReportBatch(tag: "\(batch.tag)_retry_\(attempt)", events: batch.events))
        }
    }

    private func post(data: Data) {
        guard let url = URL(string: endpoint) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        session.dataTask(with: request).resume()
    }
}
