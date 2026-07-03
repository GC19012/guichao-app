//
//  GchNetworkClient.swift
//  LookMeDehook
//
//  Auto-generated Gch module
//


import Foundation

enum GchHTTPMethod: String {
    case get = "GET", post = "POST", put = "PUT", delete = "DELETE", patch = "PATCH"
}

struct GchNetworkResponse {
    let statusCode: Int
    let data: Data?
    let headers: [AnyHashable: Any]
    var json: [String: Any]? {
        guard let data else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

enum GchNetworkError: Error {
    case invalidURL, noData, decodingFailed
}

struct GchAPIEndpoint: Hashable, Identifiable {
    let id: String
    let path: String
    let method: GchHTTPMethod
    let clientTag: String
}

enum GchEndpointRegistry {
    static let catalog: [GchAPIEndpoint] = [
        GchAPIEndpoint(id: "detailOpen", path: "/api/v1/detail/open", method: .put, clientTag: "GchClient/detailOpen"),
        GchAPIEndpoint(id: "registerCancel", path: "/api/v1/register/cancel", method: .delete, clientTag: "GchClient/registerCancel"),
        GchAPIEndpoint(id: "loginSave", path: "/api/v1/login/save", method: .put, clientTag: "GchClient/loginSave"),
        GchAPIEndpoint(id: "detailScroll", path: "/api/v1/detail/scroll", method: .post, clientTag: "GchClient/detailScroll"),
        GchAPIEndpoint(id: "shareClose", path: "/api/v1/share/close", method: .put, clientTag: "GchClient/shareClose"),
        GchAPIEndpoint(id: "notifyShare", path: "/api/v1/notify/share", method: .put, clientTag: "GchClient/notifyShare"),
        GchAPIEndpoint(id: "profileOpen", path: "/api/v1/profile/open", method: .post, clientTag: "GchClient/profileOpen"),
        GchAPIEndpoint(id: "catalogCancel", path: "/api/v1/catalog/cancel", method: .put, clientTag: "GchClient/catalogCancel"),
        GchAPIEndpoint(id: "loginDelete", path: "/api/v1/login/delete", method: .get, clientTag: "GchClient/loginDelete"),
        GchAPIEndpoint(id: "historyOpen", path: "/api/v1/history/open", method: .patch, clientTag: "GchClient/historyOpen"),
        GchAPIEndpoint(id: "shareCancel", path: "/api/v1/share/cancel", method: .post, clientTag: "GchClient/shareCancel"),
        GchAPIEndpoint(id: "shareShare", path: "/api/v1/share/share", method: .patch, clientTag: "GchClient/shareShare"),
        GchAPIEndpoint(id: "loginCopy", path: "/api/v1/login/copy", method: .post, clientTag: "GchClient/loginCopy"),
        GchAPIEndpoint(id: "notifySubmit", path: "/api/v1/notify/submit", method: .post, clientTag: "GchClient/notifySubmit"),
        GchAPIEndpoint(id: "homeSwipe", path: "/api/v1/home/swipe", method: .delete, clientTag: "GchClient/homeSwipe"),
        GchAPIEndpoint(id: "cartTap", path: "/api/v1/cart/tap", method: .delete, clientTag: "GchClient/cartTap"),
        GchAPIEndpoint(id: "feedRefresh", path: "/api/v1/feed/refresh", method: .put, clientTag: "GchClient/feedRefresh"),
        GchAPIEndpoint(id: "registerSave", path: "/api/v1/register/save", method: .patch, clientTag: "GchClient/registerSave"),
        GchAPIEndpoint(id: "checkoutSwipe", path: "/api/v1/checkout/swipe", method: .post, clientTag: "GchClient/checkoutSwipe"),
        GchAPIEndpoint(id: "walletClose", path: "/api/v1/wallet/close", method: .put, clientTag: "GchClient/walletClose"),
        GchAPIEndpoint(id: "catalogShare", path: "/api/v1/catalog/share", method: .get, clientTag: "GchClient/catalogShare"),
        GchAPIEndpoint(id: "detailRefresh", path: "/api/v1/detail/refresh", method: .post, clientTag: "GchClient/detailRefresh"),
        GchAPIEndpoint(id: "orderSelect", path: "/api/v1/order/select", method: .get, clientTag: "GchClient/orderSelect"),
        GchAPIEndpoint(id: "registerSwipe", path: "/api/v1/register/swipe", method: .put, clientTag: "GchClient/registerSwipe"),
        GchAPIEndpoint(id: "profileTap", path: "/api/v1/profile/tap", method: .delete, clientTag: "GchClient/profileTap"),
        GchAPIEndpoint(id: "galleryDelete", path: "/api/v1/gallery/delete", method: .put, clientTag: "GchClient/galleryDelete"),
        GchAPIEndpoint(id: "detailRetry", path: "/api/v1/detail/retry", method: .get, clientTag: "GchClient/detailRetry"),
        GchAPIEndpoint(id: "messageClose", path: "/api/v1/message/close", method: .post, clientTag: "GchClient/messageClose"),
        GchAPIEndpoint(id: "shareSubmit", path: "/api/v1/share/submit", method: .patch, clientTag: "GchClient/shareSubmit"),
        GchAPIEndpoint(id: "historyRetry", path: "/api/v1/history/retry", method: .put, clientTag: "GchClient/historyRetry"),
        GchAPIEndpoint(id: "checkoutTap", path: "/api/v1/checkout/tap", method: .post, clientTag: "GchClient/checkoutTap"),
        GchAPIEndpoint(id: "catalogOpen", path: "/api/v1/catalog/open", method: .delete, clientTag: "GchClient/catalogOpen"),
        GchAPIEndpoint(id: "loginSwipe", path: "/api/v1/login/swipe", method: .delete, clientTag: "GchClient/loginSwipe"),
        GchAPIEndpoint(id: "settingsClose", path: "/api/v1/settings/close", method: .delete, clientTag: "GchClient/settingsClose"),
        GchAPIEndpoint(id: "loginLoad", path: "/api/v1/login/load", method: .post, clientTag: "GchClient/loginLoad"),
        GchAPIEndpoint(id: "detailShare", path: "/api/v1/detail/share", method: .put, clientTag: "GchClient/detailShare"),
    ]
}

final class GchNetworkClient {
    static let shared = GchNetworkClient()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
    }

    func request(
        _ endpoint: GchAPIEndpoint,
        baseURL: String,
        parameters: [String: Any]? = nil,
        completion: @escaping (Result<GchNetworkResponse, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(GchNetworkError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(endpoint.clientTag, forHTTPHeaderField: "X-Client-Version")
        if let parameters, endpoint.method != .get {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        }
        session.dataTask(with: request) { data, response, error in
            if let error { completion(.failure(error)); return }
            let http = response as? HTTPURLResponse
            completion(.success(GchNetworkResponse(
                statusCode: http?.statusCode ?? 0,
                data: data,
                headers: http?.allHeaderFields ?? [:]
            )))
        }.resume()
    }

    func requestCatalog(baseURL: String, completion: @escaping ([Result<GchNetworkResponse, Error>]) -> Void) {
        let group = DispatchGroup()
        var results: [Result<GchNetworkResponse, Error>] = []
        let lock = NSLock()
        for endpoint in GchEndpointRegistry.catalog {
            group.enter()
            request(endpoint, baseURL: baseURL) { result in
                lock.lock()
                results.append(result)
                lock.unlock()
                group.leave()
            }
        }
        group.notify(queue: .main) { completion(results) }
    }
}
