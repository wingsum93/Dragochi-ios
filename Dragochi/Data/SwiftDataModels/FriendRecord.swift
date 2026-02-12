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

    @Relationship(deleteRule: .cascade, inverse: \SessionFriendRecord.friend)
    var sessionFriends: [SessionFriendRecord] = []

    init(
        id: UUID = UUID(),
        name: String,
        handle: String? = nil
    ) {
        self.id = id
        self.name = name
        self.handle = handle
    }
}

extension FriendRecord {
    func toEntity() -> FriendEntity {
        FriendEntity(id: id, name: name, handle: handle)
    }
}

