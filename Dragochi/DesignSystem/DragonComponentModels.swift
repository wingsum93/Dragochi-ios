//
//  DragonComponentModels.swift
//  Dragochi
//
//  Created by Codex on 17/2/2026.
//

import Foundation

struct GameCardModel: Identifiable, Hashable {
    let id: String
    let title: String
    let imageAssetName: String?
}

struct TeammateChipModel: Identifiable, Hashable {
    let id: String
    let name: String
    let avatarAssetName: String?
    let avatarURL: URL?

    init(
        id: String,
        name: String,
        avatarAssetName: String? = nil,
        avatarURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.avatarAssetName = avatarAssetName
        self.avatarURL = avatarURL
    }
}

struct PlatformOption: Identifiable, Hashable {
    let id: String
    let iconName: String
    let title: String
    var isEnabled: Bool = true
}

struct NotesQuickAction: Identifiable, Hashable {
    let id: String
    let iconName: String
}

struct DragonResumeLastSetupModel: Identifiable, Hashable {
    let id: UUID
    let gameTitle: String
    let gameImageAssetName: String?
    let platformLabel: String
    let teammatesLabel: String
}
