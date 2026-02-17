//
//  FriendAvatarOptions.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import Foundation

enum FriendAvatarOptions {
    static let assetNames: [String] = [
        "M1", "M2", "M3", "M4", "M5", "M6", "M7", "M8", "M9", "M10",
        "F1", "F2", "F3", "F4", "F5"
    ]

    static let defaultAssetName = "M1"

    static func isValid(assetName: String?) -> Bool {
        guard let assetName else { return false }
        return assetNames.contains(assetName)
    }
}
