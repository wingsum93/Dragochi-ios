//
//  SessionRecord.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import SwiftData

@Model
final class SessionRecord {
    var id: UUID
    var startAt: Date
    var endAt: Date?
    var durationSeconds: Int?
    var platformRawValue: String
    var note: String?
    var game: GameRecord?

    @Relationship(deleteRule: .cascade, inverse: \SessionFriendRecord.session)
    var sessionFriends: [SessionFriendRecord] = []

    init(
        id: UUID = UUID(),
        startAt: Date,
        endAt: Date? = nil,
        durationSeconds: Int? = nil,
        platformRawValue: String,
        note: String? = nil,
        game: GameRecord? = nil
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.durationSeconds = durationSeconds
        self.platformRawValue = platformRawValue
        self.note = note
        self.game = game
    }
}

extension SessionRecord {
    func toEntity() throws -> SessionEntity {
        guard let platform = Platform(rawValue: platformRawValue) else {
            throw RepositoryError.invalidPlatformRawValue(platformRawValue)
        }

        let friendIDs = sessionFriends
            .compactMap { $0.friend?.id }
            .sorted()

        return SessionEntity(
            id: id,
            startAt: startAt,
            endAt: endAt,
            platform: platform,
            gameID: game?.id,
            note: note,
            friendIDs: friendIDs
        )
    }
}

