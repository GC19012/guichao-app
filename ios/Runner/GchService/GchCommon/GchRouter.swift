//
//  GchRouter.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//

import UIKit

enum GchRoute: String, CaseIterable {
    case detailPage = "detailPage"
    case registerPage = "registerPage"
    case loginPage = "loginPage"
    case detailPanel = "detailPanel"
    case sharePage = "sharePage"
    case notifyScreen = "notifyScreen"
    case profilePage = "profilePage"
    case catalogPage = "catalogPage"
    case loginPanel = "loginPanel"
    case historyPage = "historyPage"
    case shareScreen = "shareScreen"
    case loginScreen = "loginScreen"
    case homePage = "homePage"
    case feedScreen = "feedScreen"
    case checkoutScreen = "checkoutScreen"
    case messagePage = "messagePage"
    case orderScreen = "orderScreen"
    case historyScreen = "historyScreen"
    case profilePanel = "profilePanel"
    case galleryPanel = "galleryPanel"
    case detailScreen = "detailScreen"
    case catalogPanel = "catalogPanel"
    case settingsPanel = "settingsPanel"
    case notifyPage = "notifyPage"
    case registerScreen = "registerScreen"
    case orderPage = "orderPage"
    case checkoutPanel = "checkoutPanel"
    case registerPanel = "registerPanel"
    case cartPanel = "cartPanel"
    case galleryScreen = "galleryScreen"
    case walletPage = "walletPage"
    case walletScreen = "walletScreen"
    case editorScreen = "editorScreen"
    case galleryPage = "galleryPage"
    case sharePanel = "sharePanel"
    case searchPanel = "searchPanel"
    case editorPage = "editorPage"
    case feedPanel = "feedPanel"
    case catalogScreen = "catalogScreen"
    case messagePanel = "messagePanel"
}

final class GchRouter {
    static let shared = GchRouter()
    weak var navigationController: UINavigationController?
    private init() {}

    func navigate(to route: GchRoute, animated: Bool = true, params: [String: Any] = [:]) {
        guard let nav = navigationController else { return }
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        vc.title = route.rawValue
        vc.restorationIdentifier = route.rawValue
        nav.pushViewController(vc, animated: animated)
        GchEventTracker.shared.trackPageView(page: route.rawValue, params: params)
    }

    func navigateRandom(seed: UInt64, animated: Bool = true) {
        let routes = GchShuffleAlgorithm.sample(Array(GchRoute.allCases), count: 1, seed: seed)
        guard let route = routes.first else { return }
        navigate(to: route, animated: animated)
    }
}
