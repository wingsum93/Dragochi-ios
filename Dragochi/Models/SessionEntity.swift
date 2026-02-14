//
//  SessionEntity.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

struct SessionEntity: Identifiable, Codable, Hashable {
    let id: UUID
    var startAt: Date
    var endAt: Date?
    var durationSeconds: Int?
    var platform: Platform
    var gameID: UUID?
    var note: String?
    var friendIDs: [UUID]

    init(
        id: UUID = UUID(),
        startAt: Date,
        endAt: Date? = nil,
        durationSeconds: Int? = nil,
        platform: Platform,
        gameID: UUID? = nil,
        note: String? = nil,
        friendIDs: [UUID] = []
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.durationSeconds = durationSeconds
        self.platform = platform
        self.gameID = gameID
        self.note = note
        self.friendIDs = friendIDs
    }
}

extension SessionEntity {
    var isRunning: Bool {
        endAt == nil
    }
}
