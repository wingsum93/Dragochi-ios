//
//  SwiftDataFriendRepository.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataFriendRepository: FriendRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func create(name: String, handle: String?) throws -> FriendEntity {
        let record = FriendRecord(name: name, handle: handle)
        modelContext.insert(record)
        try modelContext.save()
        return record.toEntity()
    }

    func upsert(_ friend: FriendEntity) throws -> FriendEntity {
        if let existing = try fetchRecord(id: friend.id) {
            existing.name = friend.name
            existing.handle = friend.handle
            try modelContext.save()
            return existing.toEntity()
        }

        let record = FriendRecord(id: friend.id, name: friend.name, handle: friend.handle)
        modelContext.insert(record)
        try modelContext.save()
        return record.toEntity()
    }

    func fetch(id: UUID) throws -> FriendEntity? {
        try fetchRecord(id: id)?.toEntity()
    }

    func fetchAll() throws -> [FriendEntity] {
        let descriptor = FetchDescriptor<FriendRecord>()
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func delete(id: UUID) throws {
        guard let existing = try fetchRecord(id: id) else { throw RepositoryError.notFound }
        modelContext.delete(existing)
        try modelContext.save()
    }

    private func fetchRecord(id: UUID) throws -> FriendRecord? {
        let descriptor = FetchDescriptor<FriendRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
}

