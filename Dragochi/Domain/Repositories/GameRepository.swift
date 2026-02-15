//
//  GameRepository.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

@MainActor
protocol GameRepository {
    func create(name: String, imageAssetName: String?, remoteID: String?) throws -> GameEntity
    func upsert(_ game: GameEntity) throws -> GameEntity
    func fetch(id: UUID) throws -> GameEntity?
    func fetch(remoteID: String) throws -> GameEntity?
    func fetchAll() throws -> [GameEntity]
    func referencedGameIDs() throws -> Set<UUID>
    func delete(id: UUID) throws
}
