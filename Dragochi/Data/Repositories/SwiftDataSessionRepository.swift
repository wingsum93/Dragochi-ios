//
//  SwiftDataSessionRepository.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataSessionRepository: SessionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func create(
        startAt: Date,
        endAt: Date?,
        platform: Platform,
        gameID: UUID?,
        durationSeconds: Int?,
        note: String?,
        friendIDs: [UUID]
    ) throws -> SessionEntity {
        let game = try fetchGameRecord(id: gameID)
        let resolvedDuration = durationSeconds ?? Self.computeDurationSeconds(startAt: startAt, endAt: endAt)

        let record = SessionRecord(
            startAt: startAt,
            endAt: endAt,
            durationSeconds: resolvedDuration,
            platformRawValue: platform.rawValue,
            note: note,
            game: game
        )

        modelContext.insert(record)

        let friends = try fetchFriendRecords(ids: friendIDs)
        try replaceSessionFriends(for: record, friends: friends)

        try modelContext.save()
        return try record.toEntity()
    }

    func update(_ session: SessionEntity) throws -> SessionEntity {
        guard let record = try fetchSessionRecord(id: session.id) else { throw RepositoryError.notFound }

        record.startAt = session.startAt
        record.endAt = session.endAt
        record.durationSeconds = session.durationSeconds
            ?? Self.computeDurationSeconds(startAt: session.startAt, endAt: session.endAt)
        record.platformRawValue = session.platform.rawValue
        record.note = session.note
        record.game = try fetchGameRecord(id: session.gameID)

        let friends = try fetchFriendRecords(ids: session.friendIDs)
        try replaceSessionFriends(for: record, friends: friends)

        try modelContext.save()
        return try record.toEntity()
    }

    func fetch(id: UUID) throws -> SessionEntity? {
        guard let record = try fetchSessionRecord(id: id) else { return nil }
        return try record.toEntity()
    }

    func fetchEnded(between start: Date, and end: Date) throws -> [SessionEntity] {
        let descriptor = FetchDescriptor<SessionRecord>()
        let records: [SessionRecord] = try modelContext.fetch(descriptor)

        let endedRecords: [SessionRecord] = records.compactMap { record in
            guard let endAt = record.endAt else { return nil }
            guard endAt >= start, endAt <= end else { return nil }
            return record
        }

        let sortedRecords = endedRecords.sorted { lhs, rhs in
            (lhs.endAt ?? .distantPast) > (rhs.endAt ?? .distantPast)
        }

        return try sortedRecords.map { try $0.toEntity() }
    }

    func delete(id: UUID) throws {
        guard let record = try fetchSessionRecord(id: id) else { throw RepositoryError.notFound }
        modelContext.delete(record)
        try modelContext.save()
    }

    private func fetchSessionRecord(id: UUID) throws -> SessionRecord? {
        let descriptor = FetchDescriptor<SessionRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func fetchGameRecord(id: UUID?) throws -> GameRecord? {
        guard let id else { return nil }
        let descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func fetchFriendRecords(ids: [UUID]) throws -> [FriendRecord] {
        let uniqueIDs = Array(Set(ids)).sorted(by: { $0.uuidString < $1.uuidString })
        guard !uniqueIDs.isEmpty else { return [] }

        let descriptor = FetchDescriptor<FriendRecord>(
            predicate: #Predicate { uniqueIDs.contains($0.id) }
        )
        let records = try modelContext.fetch(descriptor)

        if records.count != uniqueIDs.count {
            let found = Set(records.map(\.id))
            let missing = uniqueIDs.filter { !found.contains($0) }
            throw RepositoryError.constraint("Missing friend IDs: \(missing.map(\.uuidString).joined(separator: ","))")
        }

        return records
    }

    private func replaceSessionFriends(for session: SessionRecord, friends: [FriendRecord]) throws {
        for join in session.sessionFriends {
            modelContext.delete(join)
        }
        session.sessionFriends = []

        for friend in friends {
            let join = SessionFriendRecord(session: session, friend: friend)
            modelContext.insert(join)
            session.sessionFriends.append(join)
        }
    }

    private static func computeDurationSeconds(startAt: Date, endAt: Date?) -> Int? {
        guard let endAt else { return nil }
        return max(0, Int(endAt.timeIntervalSince(startAt)))
    }
}
