//
//  AddSessionView.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

struct AddSessionView: View {
    @StateObject private var store: AddSessionStore

    init(store: AddSessionStore) {
        _store = StateObject(wrappedValue: store)
    }

    private let platforms: [PlatformOption] = [
        .init(id: "pc", iconName: "desktopcomputer", title: "PC"),
        .init(id: "console", iconName: "gamecontroller", title: "Console"),
        .init(id: "mobile", iconName: "iphone", title: "Mobile")
    ]

    var body: some View {
        DragonBottomSheetContainer(
            topInset: 24,
            contentTopPadding: DragonTheme.current.spacing(.xs)
        ) {
            VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.xl)) {
                DragonSessionHero(
                    title: heroTitle,
                    durationText: heroDuration,
                    trendText: heroTrendText,
                    trendDirection: heroTrendDirection
                )
                .accessibilityIdentifier("hero.addSessionTitle")

                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    DragonSectionHeader(
                        title: "Game Played",
                        trailingText: "See all",
                        trailingAction: {}
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DragonTheme.current.spacing(.sm)) {
                            ForEach(store.state.gameCards) { game in
                                DragonSelectableGameCard(
                                    model: game,
                                    state: selectionState(for: game),
                                    action: {
                                        if game.id != "add", let uuid = UUID(uuidString: game.id) {
                                            store.send(.selectGame(uuid))
                                        }
                                    }
                                )
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    DragonSectionHeader(title: "Platform")
                    HStack(spacing: DragonTheme.current.spacing(.sm)) {
                        ForEach(platforms) { option in
                            DragonPlatformPill(platform: option, isSelected: option.id == store.state.selectedPlatform.rawValue) {
                                if let platform = Platform(rawValue: option.id) {
                                    store.send(.selectPlatform(platform))
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    DragonSectionHeader(
                        title: "Teammates",
                        trailingText: "\(store.state.selectedFriendIDs.count) selected"
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DragonTheme.current.spacing(.md)) {
                            ForEach(store.state.teammateChips) { teammate in
                                let uuid = UUID(uuidString: teammate.id)
                                DragonTeammateAvatarChip(
                                    model: teammate,
                                    state: uuid.map { store.state.selectedFriendIDs.contains($0) } == true ? .selected : .unselected
                                ) {
                                    if let uuid {
                                        store.send(.toggleFriend(uuid))
                                    }
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
                        text: Binding(
                            get: { store.state.note },
                            set: { store.send(.updateNote($0)) }
                        ),
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
                    title: primaryButtonTitle,
                    icon: "arrow.right",
                    state: store.state.isSaving ? .loading : .enabled,
                    action: { store.send(.saveTapped) }
                )
                .accessibilityIdentifier("action.saveSession")
                DragonTextButton(
                    title: secondaryButtonTitle,
                    state: .enabled,
                    action: { store.send(.discardTapped) }
                )
                if let errorMessage = store.state.errorMessage {
                    Text(errorMessage)
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .accessibilityIdentifier("screen.addSession")
        .onAppear { store.send(.onAppear) }
    }

    private func selectionState(for card: GameCardModel) -> SelectionState {
        guard card.id != "add" else { return .add }
        if card.id == store.state.selectedGameID?.uuidString {
            return .selected
        }
        return .unselected
    }

    private var formattedDuration: String {
        let seconds = max(0, Int(store.state.endAt.timeIntervalSince(store.state.startAt)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remaining)
    }

    private var heroTitle: String {
        store.state.mode == .preStartSetup ? "Session Setup" : "Session Complete"
    }

    private var heroDuration: String? {
        store.state.mode == .preStartSetup ? nil : formattedDuration
    }

    private var heroTrendText: String {
        store.state.mode == .preStartSetup ? "Ready to start tracking" : "+15% vs avg"
    }

    private var heroTrendDirection: TrendDirection {
        store.state.mode == .preStartSetup ? .neutral : .up
    }

    private var primaryButtonTitle: String {
        store.state.mode == .preStartSetup ? "Start Tracking" : "Save Session"
    }

    private var secondaryButtonTitle: String {
        store.state.mode == .preStartSetup ? "Cancel" : "Discard Entry"
    }
}
