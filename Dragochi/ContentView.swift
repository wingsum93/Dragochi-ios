//
//  ContentView.swift
//  Dragochi
//
//  Created by eric ho on 11/2/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedGameID = "valorant"
    @State private var selectedPlatformID = "pc"
    @State private var selectedTeammates: Set<String> = ["m1", "f1"]
    @State private var notes = ""

    private let games: [GameCardModel] = [
        .init(id: "valorant", title: "Valorant", imageURL: URL(string: "https://www.figma.com/api/mcp/asset/5e99ed29-61aa-429d-9859-4ac4ee9efaa0")),
        .init(id: "lol", title: "LoL", imageURL: URL(string: "https://www.figma.com/api/mcp/asset/c2898203-26fd-4144-8c9c-086806a4a809")),
        .init(id: "genshin", title: "Genshin", imageURL: URL(string: "https://www.figma.com/api/mcp/asset/1b2b8dae-8c5c-4f6f-9a74-b1dbf1f7d174"))
    ]

    private let platforms: [PlatformOption] = [
        .init(id: "pc", iconName: "desktopcomputer", title: "PC"),
        .init(id: "console", iconName: "gamecontroller", title: "Console"),
        .init(id: "mobile", iconName: "iphone", title: "Mobile")
    ]

    private let teammates: [TeammateChipModel] = [
        .init(id: "m1", name: "Mason", avatarAssetName: "M1"),
        .init(id: "m2", name: "Kai", avatarAssetName: "M2"),
        .init(id: "m3", name: "Noah", avatarAssetName: "M3"),
        .init(id: "m4", name: "Leo", avatarAssetName: "M4"),
        .init(id: "m5", name: "Aiden", avatarAssetName: "M5"),
        .init(id: "m6", name: "Ryan", avatarAssetName: "M6"),
        .init(id: "m7", name: "Evan", avatarAssetName: "M7"),
        .init(id: "m8", name: "Jude", avatarAssetName: "M8"),
        .init(id: "m9", name: "Liam", avatarAssetName: "M9"),
        .init(id: "m10", name: "Owen", avatarAssetName: "M10"),
        .init(id: "f1", name: "Ava", avatarAssetName: "F1"),
        .init(id: "f2", name: "Mia", avatarAssetName: "F2"),
        .init(id: "f3", name: "Luna", avatarAssetName: "F3"),
        .init(id: "f4", name: "Ivy", avatarAssetName: "F4"),
        .init(id: "f5", name: "Nora", avatarAssetName: "F5")
    ]

    var body: some View {
        DragonBottomSheetContainer {
            VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.xl)) {
                DragonSessionHero(
                    title: "Session Complete",
                    durationText: "02:14:35",
                    trendText: "+15% vs avg",
                    trendDirection: .up
                )

                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    DragonSectionHeader(
                        title: "Game Played",
                        trailingText: "See all",
                        trailingAction: {}
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DragonTheme.current.spacing(.sm)) {
                            ForEach(games) { game in
                                DragonSelectableGameCard(
                                    model: game,
                                    state: game.id == selectedGameID ? .selected : .unselected
                                ) {
                                    selectedGameID = game.id
                                }
                            }
                            DragonSelectableGameCard(
                                model: .init(id: "add", title: "Add", imageURL: nil),
                                state: .add,
                                action: {}
                            )
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    DragonSectionHeader(title: "Platform")
                    HStack(spacing: DragonTheme.current.spacing(.sm)) {
                        ForEach(platforms) { option in
                            DragonPlatformPill(platform: option, isSelected: option.id == selectedPlatformID) {
                                selectedPlatformID = option.id
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    DragonSectionHeader(
                        title: "Teammates",
                        trailingText: "\(selectedTeammates.count) selected"
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DragonTheme.current.spacing(.md)) {
                            ForEach(teammates) { teammate in
                                DragonTeammateAvatarChip(
                                    model: teammate,
                                    state: selectedTeammates.contains(teammate.id) ? .selected : .unselected
                                ) {
                                    toggleTeammate(id: teammate.id)
                                }
                            }
                            DragonTeammateAvatarChip(
                                model: .init(id: "add", name: "Add"),
                                state: .add,
                                action: {}
                            )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    DragonSectionHeader(title: "Session Notes")
                    DragonNotesInput(
                        text: $notes,
                        placeholder: "Rank change, highlights, or mood...",
                        actions: [
                            .init(id: "mood", iconName: "face.smiling"),
                            .init(id: "tag", iconName: "tag")
                        ]
                    )
                }
            }
        } footer: {
            VStack(spacing: DragonTheme.current.spacing(.md)) {
                DragonPrimaryCTAButton(
                    title: "Save Session",
                    icon: "arrow.right",
                    state: .enabled,
                    action: {}
                )
                DragonTextButton(title: "Discard Entry", state: .enabled, action: {})
            }
        }
    }

    private func toggleTeammate(id: String) {
        if selectedTeammates.contains(id) {
            selectedTeammates.remove(id)
        } else {
            selectedTeammates.insert(id)
        }
    }
}

#Preview {
    ContentView()
}
