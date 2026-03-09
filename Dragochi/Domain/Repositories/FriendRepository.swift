//
//  FriendRepository.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

@MainActor
protocol FriendRepository {
    func create(
        name: String,
        handle: String?,
        avatarAssetName: String?,
        isActive: Bool,
        order: Int,
        note: String?
    ) throws -> FriendEntity
    func upsert(_ friend: FriendEntity) throws -> FriendEntity
    func fetch(id: UUID) throws -> FriendEntity?
    func fetchActive() throws -> [FriendEntity]
    func fetchAll() throws -> [FriendEntity]
    func delete(id: UUID) throws
}

extension FriendRepository {
    func create(
        name: String,
        handle: String?,
        avatarAssetName: String?,
        isActive: Bool
    ) throws -> FriendEntity {
        try create(name: name, handle: handle, avatarAssetName: avatarAssetName, isActive: isActive, order: 0, note: nil)
    }

    func create(
        name: String,
        handle: String?,
        avatarAssetName: String?,
        isActive: Bool,
        note: String?
    ) throws -> FriendEntity {
        try create(name: name, handle: handle, avatarAssetName: avatarAssetName, isActive: isActive, order: 0, note: note)
    }

    func create(name: String, handle: String?) throws -> FriendEntity {
        try create(name: name, handle: handle, avatarAssetName: nil, isActive: true, order: 0, note: nil)
    }
}
