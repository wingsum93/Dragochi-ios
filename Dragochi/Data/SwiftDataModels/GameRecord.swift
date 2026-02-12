//
//  GameRecord.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import SwiftData

@Model
final class GameRecord {
    var id: UUID
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

extension GameRecord {
    func toEntity() -> GameEntity {
        GameEntity(id: id, name: name, icon: icon)
    }
}

