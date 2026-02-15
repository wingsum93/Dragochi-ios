//
//  SwiftDataGameRepository.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataGameRepository: GameRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func create(name: String, imageAssetName: String?, remoteID: String?) throws -> GameEntity {
        let record = GameRecord(
            name: name,
            imageAssetName: imageAssetName,
            icon: imageAssetName,
            remoteID: remoteID
        )
        modelContext.insert(record)
        try modelContext.save()
        return record.toEntity()
    }

    func upsert(_ game: GameEntity) throws -> GameEntity {
        if let existing = try fetchRecord(id: game.id) {
            existing.name = game.name
            existing.imageAssetName = game.imageAssetName
            existing.icon = game.imageAssetName
            existing.remoteID = game.remoteID
            try modelContext.save()
            return existing.toEntity()
        }

        let record = GameRecord(
            id: game.id,
            name: game.name,
            imageAssetName: game.imageAssetName,
            icon: game.imageAssetName,
            remoteID: game.remoteID
        )
        modelContext.insert(record)
        try modelContext.save()
        return record.toEntity()
    }

    func fetch(id: UUID) throws -> GameEntity? {
        try fetchRecord(id: id)?.toEntity()
    }

    func fetch(remoteID: String) throws -> GameEntity? {
        try fetchRecord(remoteID: remoteID)?.toEntity()
    }

    func fetchAll() throws -> [GameEntity] {
        let descriptor = FetchDescriptor<GameRecord>()
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
    }

    func referencedGameIDs() throws -> Set<UUID> {
        let descriptor = FetchDescriptor<SessionRecord>()
        let sessions = try modelContext.fetch(descriptor)
        return Set(sessions.compactMap { $0.game?.id })
    }

    func delete(id: UUID) throws {
        guard let existing = try fetchRecord(id: id) else { throw RepositoryError.notFound }
        modelContext.delete(existing)
        try modelContext.save()
    }

    private func fetchRecord(id: UUID) throws -> GameRecord? {
        let descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func fetchRecord(remoteID: String) throws -> GameRecord? {
        let descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.remoteID == remoteID }
        )
        return try modelContext.fetch(descriptor).first
    }
}
