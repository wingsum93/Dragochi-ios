//
//  FriendRecord.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import SwiftData

@Model
final class FriendRecord {
    var id: UUID
    var name: String
    var handle: String?
    var avatarAssetName: String?
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \SessionFriendRecord.friend)
    var sessionFriends: [SessionFriendRecord] = []

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

extension FriendRecord {
    func toEntity() -> FriendEntity {
        FriendEntity(
            id: id,
            name: name,
            handle: handle,
            avatarAssetName: avatarAssetName,
            isActive: isActive
        )
    }
}
