//
//  UITestFriendFixture.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import Foundation

struct UITestFriendFixture: Decodable {
    let name: String
    let avatarAssetName: String?

    var resolvedAvatarAssetName: String {
        guard FriendAvatarOptions.isValid(assetName: avatarAssetName) else {
            return FriendAvatarOptions.defaultAssetName
        }
        return avatarAssetName ?? FriendAvatarOptions.defaultAssetName
    }

    var resolvedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
