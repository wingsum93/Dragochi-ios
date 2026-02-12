//
//  GameEntity.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

struct GameEntity: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
    }
}

