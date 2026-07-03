//
//  GchFileManager.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation

enum GchStorageBucket: String, CaseIterable {
    case cache
    case documents
    case logs
    case images
    case downloads
    case exports
    case drafts
    case backup

    var folderName: String { "Gch/\(rawValue)" }
}

final class GchFileManager {
    static let shared = GchFileManager()
    private let fm = FileManager.default
    private init() {}

    static let activeBuckets: [GchStorageBucket] = [.cache, .documents, .logs, .images, .downloads, .exports, .drafts, .backup]

    func directory(for bucket: GchStorageBucket) throws -> URL {
        let url = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(bucket.folderName, isDirectory: true)
        if !fm.fileExists(atPath: url.path) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    func write(_ data: Data, filename: String, bucket: GchStorageBucket) throws -> URL {
        let fileURL = try directory(for: bucket).appendingPathComponent(filename)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    func read(filename: String, bucket: GchStorageBucket) throws -> Data {
        try Data(contentsOf: try directory(for: bucket).appendingPathComponent(filename))
    }

    func purge(bucket: GchStorageBucket) throws {
        let dir = try directory(for: bucket)
        let items = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        for item in items { try fm.removeItem(at: item) }
    }
}
