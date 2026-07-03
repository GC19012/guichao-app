//
//  GchBundleKit.swift
//  Runner
//
//  Created by Guichao on 12/26/23.
//

import Foundation

extension Bundle {
    var gchSvcId: String {
        guard let id = infoDictionary?["SERVICE_IDENTIFIER"] as? String else {
            fatalError("SERVICE_IDENTIFIER not found in Info.plist")
        }
        return id
    }

    var gchBundleId: String {
        guard let id = infoDictionary?["BASE_BUNDLE_IDENTIFIER"] as? String else {
            fatalError("BASE_BUNDLE_IDENTIFIER not found in Info.plist")
        }
        return id
    }
}
