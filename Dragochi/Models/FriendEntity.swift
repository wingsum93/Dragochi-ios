//
//  FriendEntity.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

struct FriendEntity: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var handle: String?
    var avatarAssetName: String?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        handle: String? = nil,
        avatarAssetName: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.handle = handle
        self.avatarAssetName = avatarAssetName
        self.isActive = isActive
    }
}
