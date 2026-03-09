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

    func create(
        name: String,
        handle: String?,
        avatarAssetName: String? = nil,
        isActive: Bool = true,
        order: Int = 0,
        note: String? = nil
    ) throws -> FriendEntity {
        let record = FriendRecord(
            name: name,
            handle: handle,
            avatarAssetName: avatarAssetName,
            isActive: isActive,
            order: order,
            note: note
        )
        modelContext.insert(record)
        try modelContext.save()
        return record.toEntity()
    }

    func upsert(_ friend: FriendEntity) throws -> FriendEntity {
        if let existing = try fetchRecord(id: friend.id) {
            existing.name = friend.name
            existing.handle = friend.handle
            existing.avatarAssetName = friend.avatarAssetName
            existing.isActive = friend.isActive
            existing.order = friend.order
            existing.note = friend.note
            try modelContext.save()
            return existing.toEntity()
        }

        let record = FriendRecord(
            id: friend.id,
            name: friend.name,
            handle: friend.handle,
            avatarAssetName: friend.avatarAssetName,
            isActive: friend.isActive,
            order: friend.order,
            note: friend.note
        )
        modelContext.insert(record)
        try modelContext.save()
        return record.toEntity()
    }

    func fetch(id: UUID) throws -> FriendEntity? {
        try fetchRecord(id: id)?.toEntity()
    }

    func fetchActive() throws -> [FriendEntity] {
        let descriptor = FetchDescriptor<FriendRecord>(
            predicate: #Predicate { $0.isActive == true }
        )
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
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
