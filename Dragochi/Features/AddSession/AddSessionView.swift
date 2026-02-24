//
//  AddSessionView.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

struct AddSessionView: View {
    @StateObject private var store: AddSessionStore
    @Environment(\.locale) private var locale

    init(store: AddSessionStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var platforms: [PlatformOption] {
        [
            .init(id: "pc", iconName: "desktopcomputer", title: L10n.string("title_platform_pc", locale: locale)),
            .init(id: "console", iconName: "gamecontroller", title: L10n.string("title_platform_console", locale: locale)),
            .init(id: "mobile", iconName: "iphone", title: L10n.string("title_platform_mobile", locale: locale))
        ]
    }

    var body: some View {
        DragonBottomSheetContainer(
            topInset: 24,
            contentTopPadding: DragonTheme.current.spacing(.xs)
        ) {
            VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.xl)) {
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityIdentifier("screen.addSession")

                DragonSessionHero(
                    title: heroTitle,
                    durationText: heroDuration,
                    trendText: heroTrendText,
                    trendDirection: heroTrendDirection
                )
                .accessibilityIdentifier("hero.addSessionTitle")

                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    DragonSectionHeader(
                        title: L10n.string("title_game_played", locale: locale),
                        trailingText: L10n.string("text_see_all", locale: locale),
                        trailingAction: { store.send(.addGameTapped) }
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DragonTheme.current.spacing(.sm)) {
                            ForEach(store.state.gameCards) { game in
                                DragonSelectableGameCard(
                                    model: localizedModel(for: game),
                                    state: selectionState(for: game),
                                    accessibilityIdentifier: game.id == "add"
                                        ? "action.addGame"
                                        : "action.selectGame.\(game.id)",
                                    action: {
                                        if game.id == "add" {
                                            store.send(.addGameTapped)
                                        } else if let uuid = UUID(uuidString: game.id) {
                                            store.send(.selectGame(uuid))
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                .accessibilityIdentifier("section.gamePlayed")

                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    DragonSectionHeader(title: L10n.string("title_platform", locale: locale))
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
                        title: L10n.string("title_teammates", locale: locale),
                        trailingText: L10n.format("text_selected_count", locale: locale, store.state.selectedFriendIDs.count)
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
                                model: .init(id: "add", name: L10n.string("button_add", locale: locale)),
                                state: .add,
                                action: { store.send(.addTeammateTapped) }
                            )
                            .accessibilityIdentifier("action.addTeammate")
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    DragonSectionHeader(title: L10n.string("title_session_notes", locale: locale))
                    DragonNotesInput(
                        text: Binding(
                            get: { store.state.note },
                            set: { store.send(.updateNote($0)) }
                        ),
                        placeholder: L10n.string("text_session_notes_placeholder", locale: locale),
                        actions: [
                            .init(id: "mood", iconName: "face.smiling"),
                            .init(id: "tag", iconName: "tag")
                        ]
                    )
                }
                .accessibilityIdentifier("section.sessionNotes")
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
                if let errorMessageKey = store.state.errorMessageKey {
                    Text(L10n.string(errorMessageKey, locale: locale))
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let errorMessage = store.state.errorMessage {
                    Text(errorMessage)
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .onAppear { store.send(.onAppear) }
        .onReceive(NotificationCenter.default.publisher(for: .friendsDidChange)) { _ in
            store.send(.onAppear)
        }
    }

    private func localizedModel(for model: GameCardModel) -> GameCardModel {
        guard model.id == "add" else { return model }
        return GameCardModel(id: model.id, title: L10n.string("button_add", locale: locale), imageAssetName: model.imageAssetName)
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
        store.state.mode == .preStartSetup
            ? L10n.string("title_session_setup", locale: locale)
            : L10n.string("title_session_complete", locale: locale)
    }

    private var heroDuration: String? {
        store.state.mode == .preStartSetup ? nil : formattedDuration
    }

    private var heroTrendText: String {
        store.state.mode == .preStartSetup
            ? L10n.string("text_ready_to_start_tracking", locale: locale)
            : L10n.string("text_trend_up_15", locale: locale)
    }

    private var heroTrendDirection: TrendDirection {
        store.state.mode == .preStartSetup ? .neutral : .up
    }

    private var primaryButtonTitle: String {
        store.state.mode == .preStartSetup
            ? L10n.string("button_start_tracking", locale: locale)
            : L10n.string("button_save_session", locale: locale)
    }

    private var secondaryButtonTitle: String {
        store.state.mode == .preStartSetup
            ? L10n.string("button_cancel", locale: locale)
            : L10n.string("button_discard_entry", locale: locale)
    }
}
