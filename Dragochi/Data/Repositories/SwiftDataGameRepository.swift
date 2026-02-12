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

    func create(name: String, icon: String?) throws -> GameEntity {
        let record = GameRecord(name: name, icon: icon)
        modelContext.insert(record)
        try modelContext.save()
        return record.toEntity()
    }

    func upsert(_ game: GameEntity) throws -> GameEntity {
        if let existing = try fetchRecord(id: game.id) {
            existing.name = game.name
            existing.icon = game.icon
            try modelContext.save()
            return existing.toEntity()
        }

        let record = GameRecord(id: game.id, name: game.name, icon: game.icon)
        modelContext.insert(record)
        try modelContext.save()
        return record.toEntity()
    }

    func fetch(id: UUID) throws -> GameEntity? {
        try fetchRecord(id: id)?.toEntity()
    }

    func fetchAll() throws -> [GameEntity] {
        let descriptor = FetchDescriptor<GameRecord>()
        return try modelContext.fetch(descriptor).map { $0.toEntity() }
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
}

