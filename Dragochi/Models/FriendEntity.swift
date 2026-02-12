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

