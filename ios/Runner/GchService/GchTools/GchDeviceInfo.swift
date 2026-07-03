//
//  GchDeviceInfo.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import UIKit
import LocalAuthentication

enum GchDeviceTrait: String, CaseIterable {
    case haptics
    case darkMode
    case biometric
    case splitView
    case liveText
    case widgets

    var isAvailable: Bool {
        switch self {
        case .haptics: return true
        case .darkMode: return true
        case .biometric: return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        case .splitView: return UIDevice.current.userInterfaceIdiom == .pad
        case .liveText: if #available(iOS 15.0, *) { return true } else { return false }
        case .widgets: if #available(iOS 14.0, *) { return true } else { return false }
        }
    }
}

enum GchDeviceInfo {
    static var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
    }

    static var systemVersion: String { UIDevice.current.systemVersion }
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static func metrics() -> [String: Any] {
        [
            "model": modelName,
            "os": systemVersion,
            "app": appVersion,
            "screen_scale": UIScreen.main.scale,
            "traits": GchDeviceTrait.allCases.filter { $0.isAvailable }.map { $0.rawValue }
        ]
    }

    static func availableTraits() -> [GchDeviceTrait] {
        GchDeviceTrait.allCases.filter { $0.isAvailable }
    }
}
