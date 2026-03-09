//
//  FriendEntity.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

struct FriendEntity: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var handle: String?
    var avatarAssetName: String?
    var isActive: Bool
    var order: Int
    var note: String?

    init(
        id: UUID = UUID(),
        name: String,
        handle: String? = nil,
        avatarAssetName: String? = nil,
        isActive: Bool = true,
        order: Int = 0,
        note: String? = nil
    ) {
        self.id = id
        self.name = name
        self.handle = handle
        self.avatarAssetName = avatarAssetName
        self.isActive = isActive
        self.order = order
        self.note = note
    }
}

extension FriendEntity {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case handle
        case avatarAssetName
        case isActive
        case order
        case note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        handle = try container.decodeIfPresent(String.self, forKey: .handle)
        avatarAssetName = try container.decodeIfPresent(String.self, forKey: .avatarAssetName)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        note = try container.decodeIfPresent(String.self, forKey: .note)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(handle, forKey: .handle)
        try container.encodeIfPresent(avatarAssetName, forKey: .avatarAssetName)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(order, forKey: .order)
        try container.encodeIfPresent(note, forKey: .note)
    }
}
