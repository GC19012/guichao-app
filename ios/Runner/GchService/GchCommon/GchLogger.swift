//
//  GchLogger.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation
import os.log

enum GchLogLevel: Int {
    case debug = 0, info, warning, error, fatal
}

final class GchLogger {
    static let shared = GchLogger()
    private let osLog = Logger(subsystem: "com.lookmedehook", category: "Gch")
    var minimumLevel: GchLogLevel = .debug
    private init() {}

    func log(_ message: String, level: GchLogLevel = .info, file: String = #file, line: Int = #line) {
        guard level.rawValue >= minimumLevel.rawValue else { return }
        let prefix = "[Gch]"
        let osLevel: OSLogType = {
            switch level {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .fatal: return .fault
            }
        }()
        osLog.log(level: osLevel, "\(prefix) \(message) (\(file):\(line))")
    }

    func log(_ message: String, level: GchLogLevel, context: [String: Any]) {
        let ctx = context.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        log("\(message) {\(ctx)}", level: level)
    }
}
