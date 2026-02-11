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
    @State private var selectedTeammates: Set<String> = ["alex", "sarah"]
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
        .init(id: "alex", name: "Alex", avatarURL: URL(string: "https://www.figma.com/api/mcp/asset/daeb9f28-00fe-4f74-9100-3d79e9f913ff")),
        .init(id: "sarah", name: "Sarah", avatarURL: URL(string: "https://www.figma.com/api/mcp/asset/aa3cf75c-d478-45f8-b314-44c1dbf80977")),
        .init(id: "mike", name: "Mike", avatarURL: URL(string: "https://www.figma.com/api/mcp/asset/b92fdb2f-e40f-40eb-9db7-3e9c1a1eb22d"))
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
                                model: .init(id: "add", name: "Add", avatarURL: nil),
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
