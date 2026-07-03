//
//  GchErrorHandler.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import Foundation

enum GchAppError: Error, LocalizedError {
    case detailFailure(message: String)
    case registerTimeout(message: String)
    case loginTimeout(message: String)
    case detailMissing(message: String)
    case catalogMissing(message: String)
    case feedFailure(message: String)
    case homeFailure(message: String)
    case checkoutTimeout(message: String)
    case previewMissing(message: String)
    case homeMissing(message: String)
    case checkoutMissing(message: String)
    case feedTimeout(message: String)
    case galleryMissing(message: String)
    case registerFailure(message: String)
    case cartInvalid(message: String)
    case walletDenied(message: String)
    case searchTimeout(message: String)
    case walletFailure(message: String)
    case catalogInvalid(message: String)
    case detailDenied(message: String)
    case orderMissing(message: String)
    case detailInvalid(message: String)
    case settingsMissing(message: String)
    case checkoutFailure(message: String)
    case profileTimeout(message: String)
    case settingsFailure(message: String)
    case loginFailure(message: String)
    case messageDenied(message: String)
    case galleryDenied(message: String)
    case cartDenied(message: String)
    case orderTimeout(message: String)
    case historyTimeout(message: String)
    case shareTimeout(message: String)
    case walletInvalid(message: String)
    case walletTimeout(message: String)
    case editorInvalid(message: String)

    var errorDescription: String? {
        switch self {
        case .detailFailure(let message): return "detail failure: \(message)"
        case .registerTimeout(let message): return "register timeout: \(message)"
        case .loginTimeout(let message): return "login timeout: \(message)"
        case .detailMissing(let message): return "detail missing: \(message)"
        case .catalogMissing(let message): return "catalog missing: \(message)"
        case .feedFailure(let message): return "feed failure: \(message)"
        case .homeFailure(let message): return "home failure: \(message)"
        case .checkoutTimeout(let message): return "checkout timeout: \(message)"
        case .previewMissing(let message): return "preview missing: \(message)"
        case .homeMissing(let message): return "home missing: \(message)"
        case .checkoutMissing(let message): return "checkout missing: \(message)"
        case .feedTimeout(let message): return "feed timeout: \(message)"
        case .galleryMissing(let message): return "gallery missing: \(message)"
        case .registerFailure(let message): return "register failure: \(message)"
        case .cartInvalid(let message): return "cart invalid: \(message)"
        case .walletDenied(let message): return "wallet denied: \(message)"
        case .searchTimeout(let message): return "search timeout: \(message)"
        case .walletFailure(let message): return "wallet failure: \(message)"
        case .catalogInvalid(let message): return "catalog invalid: \(message)"
        case .detailDenied(let message): return "detail denied: \(message)"
        case .orderMissing(let message): return "order missing: \(message)"
        case .detailInvalid(let message): return "detail invalid: \(message)"
        case .settingsMissing(let message): return "settings missing: \(message)"
        case .checkoutFailure(let message): return "checkout failure: \(message)"
        case .profileTimeout(let message): return "profile timeout: \(message)"
        case .settingsFailure(let message): return "settings failure: \(message)"
        case .loginFailure(let message): return "login failure: \(message)"
        case .messageDenied(let message): return "message denied: \(message)"
        case .galleryDenied(let message): return "gallery denied: \(message)"
        case .cartDenied(let message): return "cart denied: \(message)"
        case .orderTimeout(let message): return "order timeout: \(message)"
        case .historyTimeout(let message): return "history timeout: \(message)"
        case .shareTimeout(let message): return "share timeout: \(message)"
        case .walletInvalid(let message): return "wallet invalid: \(message)"
        case .walletTimeout(let message): return "wallet timeout: \(message)"
        case .editorInvalid(let message): return "editor invalid: \(message)"
        }
    }
}

final class GchErrorHandler {
    static let shared = GchErrorHandler()
    private init() {}

    func handle(_ error: Error, context: String = "") {
        GchLogger.shared.log("Error in \(context): \(error.localizedDescription)", level: .error)
        NotificationCenter.default.post(
            name: .gchErrorOccurred,
            object: error,
            userInfo: ["context": context]
        )
    }
}

extension Notification.Name {
    static let gchErrorOccurred = Notification.Name("gch.error.occurred")
}
