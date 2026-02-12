//
//  StubBackupService.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

@MainActor
final class StubBackupService: BackupService {
    private let sessionRepository: SessionRepository
    private let gameRepository: GameRepository
    private let friendRepository: FriendRepository

    init(
        sessionRepository: SessionRepository,
        gameRepository: GameRepository,
        friendRepository: FriendRepository
    ) {
        self.sessionRepository = sessionRepository
        self.gameRepository = gameRepository
        self.friendRepository = friendRepository
    }

    func export() throws -> BackupPayload {
        let games = try gameRepository.fetchAll()
        let friends = try friendRepository.fetchAll()
        let sessions = try sessionRepository.fetchEnded(between: .distantPast, and: Date())
        return BackupPayload(games: games, friends: friends, sessions: sessions)
    }

    func `import`(_ payload: BackupPayload) throws {
        _ = payload
    }
}

