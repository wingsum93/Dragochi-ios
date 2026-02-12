//
//  SessionRepository.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

@MainActor
protocol SessionRepository {
    func create(
        startAt: Date,
        endAt: Date?,
        platform: Platform,
        gameID: UUID?,
        note: String?,
        friendIDs: [UUID]
    ) throws -> SessionEntity

    func update(_ session: SessionEntity) throws -> SessionEntity
    func fetch(id: UUID) throws -> SessionEntity?
    func fetchEnded(between start: Date, and end: Date) throws -> [SessionEntity]
    func delete(id: UUID) throws
}

