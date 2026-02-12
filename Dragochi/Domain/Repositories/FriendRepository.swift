//
//  FriendRepository.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

@MainActor
protocol FriendRepository {
    func create(name: String, handle: String?) throws -> FriendEntity
    func upsert(_ friend: FriendEntity) throws -> FriendEntity
    func fetch(id: UUID) throws -> FriendEntity?
    func fetchAll() throws -> [FriendEntity]
    func delete(id: UUID) throws
}

