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
        .init(id: "valorant", title: "Valorant", imageAssetName: "volarant"),
        .init(id: "lol", title: "LOL", imageAssetName: "lol"),
        .init(id: "apex", title: "Apex Legends", imageAssetName: "apex")
    ]

    private let teammates: [TeammateChipModel] = [
        .init(id: "m1", name: "Mason", avatarAssetName: "M1"),
        .init(id: "f1", name: "Ava", avatarAssetName: "F1"),
        .init(id: "legacy-url", name: "Legacy URL", avatarURL: URL(string: "https://www.figma.com/api/mcp/asset/daeb9f28-00fe-4f74-9100-3d79e9f913ff"))
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
                    DragonSelectableGameCard(model: .init(id: "add", title: "Add", imageAssetName: nil), state: .add) {}
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
                    DragonTeammateAvatarChip(model: .init(id: "add", name: "Add"), state: .add) {}
                }

                DragonSectionHeader(title: "Avatar URL Compatibility")
                HStack(spacing: 16) {
                    DragonTeammateAvatarChip(model: teammates[2], state: .unselected) {}
                    DragonTeammateAvatarChip(model: .init(id: "fallback", name: "Fallback"), state: .unselected) {}
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
