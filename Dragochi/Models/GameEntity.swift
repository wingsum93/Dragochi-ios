//
//  GameEntity.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

struct GameEntity: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var imageAssetName: String?

    init(
        id: UUID = UUID(),
        name: String,
        imageAssetName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.imageAssetName = imageAssetName
    }
}

extension GameEntity {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageAssetName
        case icon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        imageAssetName = try container.decodeIfPresent(String.self, forKey: .imageAssetName)
            ?? container.decodeIfPresent(String.self, forKey: .icon)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(imageAssetName, forKey: .imageAssetName)
        try container.encodeIfPresent(imageAssetName, forKey: .icon)
    }
}
