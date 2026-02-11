//
//  DragonComponentPreviews.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

struct DragonComponentStateMatrixView: View {
    @State private var sampleNotes = ""

    private let gameModels: [GameCardModel] = [
        .init(id: "valorant", title: "Valorant", imageURL: URL(string: "https://www.figma.com/api/mcp/asset/5e99ed29-61aa-429d-9859-4ac4ee9efaa0")),
        .init(id: "lol", title: "LoL", imageURL: URL(string: "https://www.figma.com/api/mcp/asset/c2898203-26fd-4144-8c9c-086806a4a809")),
        .init(id: "genshin", title: "Genshin", imageURL: URL(string: "https://www.figma.com/api/mcp/asset/1b2b8dae-8c5c-4f6f-9a74-b1dbf1f7d174"))
    ]

    private let teammates: [TeammateChipModel] = [
        .init(id: "alex", name: "Alex", avatarURL: URL(string: "https://www.figma.com/api/mcp/asset/daeb9f28-00fe-4f74-9100-3d79e9f913ff")),
        .init(id: "sarah", name: "Sarah", avatarURL: URL(string: "https://www.figma.com/api/mcp/asset/aa3cf75c-d478-45f8-b314-44c1dbf80977")),
        .init(id: "mike", name: "Mike", avatarURL: URL(string: "https://www.figma.com/api/mcp/asset/b92fdb2f-e40f-40eb-9db7-3e9c1a1eb22d"))
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("State Matrix")
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))

                DragonSessionHero(
                    title: "Session Complete",
                    durationText: "02:14:35",
                    trendText: "+15% vs avg",
                    trendDirection: .up
                )

                DragonSectionHeader(title: "Game Card States")
                HStack(spacing: 12) {
                    DragonSelectableGameCard(model: gameModels[0], state: .selected) {}
                    DragonSelectableGameCard(model: gameModels[1], state: .unselected) {}
                    DragonSelectableGameCard(model: .init(id: "add", title: "Add", imageURL: nil), state: .add) {}
                }

                DragonSectionHeader(title: "Platform Pill States")
                HStack(spacing: 12) {
                    DragonPlatformPill(platform: .init(id: "pc", iconName: "desktopcomputer", title: "PC"), isSelected: true) {}
                    DragonPlatformPill(platform: .init(id: "console", iconName: "gamecontroller", title: "Console"), isSelected: false) {}
                    DragonPlatformPill(platform: .init(id: "mobile", iconName: "iphone", title: "Mobile", isEnabled: false), isSelected: false) {}
                }

                DragonSectionHeader(title: "Avatar Chip States")
                HStack(spacing: 16) {
                    DragonTeammateAvatarChip(model: teammates[0], state: .selected) {}
                    DragonTeammateAvatarChip(model: teammates[1], state: .unselected) {}
                    DragonTeammateAvatarChip(model: .init(id: "add", name: "Add", avatarURL: nil), state: .add) {}
                }

                DragonSectionHeader(title: "Notes States")
                DragonNotesInput(
                    text: $sampleNotes,
                    placeholder: "Rank change, highlights, or mood...",
                    actions: [
                        .init(id: "mood", iconName: "face.smiling"),
                        .init(id: "tag", iconName: "tag")
                    ]
                )

                DragonSectionHeader(title: "CTA States")
                VStack(spacing: 12) {
                    DragonPrimaryCTAButton(title: "Save Session", icon: "arrow.right", state: .enabled) {}
                    DragonPrimaryCTAButton(title: "Save Session", icon: "arrow.right", state: .pressed) {}
                    DragonPrimaryCTAButton(title: "Save Session", icon: "arrow.right", state: .disabled) {}
                    DragonPrimaryCTAButton(title: "Save Session", icon: "arrow.right", state: .loading) {}
                    DragonTextButton(title: "Discard Entry", state: .enabled) {}
                    DragonTextButton(title: "Discard Entry", state: .pressed) {}
                    DragonTextButton(title: "Discard Entry", state: .disabled) {}
                }
            }
            .padding(24)
        }
        .background(DragonTheme.current.color(.bgBase))
    }
}

#Preview("Dragon Component Matrix") {
    DragonComponentStateMatrixView()
}
