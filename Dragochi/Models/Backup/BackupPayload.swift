//
//  BackupPayload.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

struct BackupPayload: Codable, Hashable {
    static let currentVersion = 1

    let version: Int
    let exportedAt: Date
    let games: [GameEntity]
    let friends: [FriendEntity]
    let sessions: [SessionEntity]

    init(
        version: Int = BackupPayload.currentVersion,
        exportedAt: Date = Date(),
        games: [GameEntity],
        friends: [FriendEntity],
        sessions: [SessionEntity]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.games = games
        self.friends = friends
        self.sessions = sessions
    }
}

