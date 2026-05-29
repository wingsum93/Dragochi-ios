//
//  AddSessionView.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

struct AddSessionView: View {
    @StateObject private var viewModel: AddSessionViewModel
    @Environment(\.locale) private var locale

    init(viewModel: AddSessionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                        trailingAction: { viewModel.send(.addGameTapped) }
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DragonTheme.current.spacing(.sm)) {
                            ForEach(viewModel.state.gameCards) { game in
                                DragonSelectableGameCard(
                                    model: localizedModel(for: game),
                                    state: selectionState(for: game),
                                    accessibilityIdentifier: game.id == "add"
                                        ? "action.addGame"
                                        : "action.selectGame.\(game.id)",
                                    action: {
                                        if game.id == "add" {
                                            viewModel.send(.addGameTapped)
                                        } else if let uuid = UUID(uuidString: game.id) {
                                            viewModel.send(.selectGame(uuid))
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
                            DragonPlatformPill(platform: option, isSelected: option.id == viewModel.state.selectedPlatform.rawValue) {
                                if let platform = Platform(rawValue: option.id) {
                                    viewModel.send(.selectPlatform(platform))
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    DragonSectionHeader(
                        title: L10n.string("title_teammates", locale: locale),
                        trailingText: L10n.format("text_selected_count", locale: locale, viewModel.state.selectedFriendIDs.count)
                    )

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DragonTheme.current.spacing(.md)) {
                            ForEach(viewModel.state.teammateChips) { teammate in
                                let uuid = UUID(uuidString: teammate.id)
                                DragonTeammateAvatarChip(
                                    model: teammate,
                                    state: uuid.map { viewModel.state.selectedFriendIDs.contains($0) } == true ? .selected : .unselected
                                ) {
                                    if let uuid {
                                        viewModel.send(.toggleFriend(uuid))
                                    }
                                }
                            }
                            DragonTeammateAvatarChip(
                                model: .init(id: "add", name: L10n.string("button_add", locale: locale)),
                                state: .add,
                                action: { viewModel.send(.addTeammateTapped) }
                            )
                            .accessibilityIdentifier("action.addTeammate")
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    DragonSectionHeader(title: L10n.string("title_session_notes", locale: locale))
                    DragonNotesInput(
                        text: Binding(
                            get: { viewModel.state.note },
                            set: { viewModel.send(.updateNote($0)) }
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
                    state: viewModel.state.isSaving ? .loading : .enabled,
                    action: { viewModel.send(.saveTapped) }
                )
                .accessibilityIdentifier("action.saveSession")
                DragonTextButton(
                    title: secondaryButtonTitle,
                    state: .enabled,
                    action: { viewModel.send(.discardTapped) }
                )
                if let errorMessageKey = viewModel.state.errorMessageKey {
                    Text(L10n.string(errorMessageKey, locale: locale))
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let errorMessage = viewModel.state.errorMessage {
                    Text(errorMessage)
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .onAppear { viewModel.send(.onAppear) }
        .onReceive(NotificationCenter.default.publisher(for: .friendsDidChange)) { _ in
            viewModel.send(.onAppear)
        }
    }

    private func localizedModel(for model: GameCardModel) -> GameCardModel {
        guard model.id == "add" else { return model }
        return GameCardModel(id: model.id, title: L10n.string("button_add", locale: locale), imageAssetName: model.imageAssetName)
    }

    private func selectionState(for card: GameCardModel) -> SelectionState {
        guard card.id != "add" else { return .add }
        if card.id == viewModel.state.selectedGameID?.uuidString {
            return .selected
        }
        return .unselected
    }

    private var formattedDuration: String {
        let seconds = max(0, Int(viewModel.state.endAt.timeIntervalSince(viewModel.state.startAt)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remaining)
    }

    private var heroTitle: String {
        viewModel.state.mode == .preStartSetup
            ? L10n.string("title_session_setup", locale: locale)
            : L10n.string("title_session_complete", locale: locale)
    }

    private var heroDuration: String? {
        viewModel.state.mode == .preStartSetup ? nil : formattedDuration
    }

    private var heroTrendText: String {
        viewModel.state.mode == .preStartSetup
            ? L10n.string("text_ready_to_start_tracking", locale: locale)
            : L10n.string("text_trend_up_15", locale: locale)
    }

    private var heroTrendDirection: TrendDirection {
        viewModel.state.mode == .preStartSetup ? .neutral : .up
    }

    private var primaryButtonTitle: String {
        viewModel.state.mode == .preStartSetup
            ? L10n.string("button_start_tracking", locale: locale)
            : L10n.string("button_save_session", locale: locale)
    }

    private var secondaryButtonTitle: String {
        viewModel.state.mode == .preStartSetup
            ? L10n.string("button_cancel", locale: locale)
            : L10n.string("button_discard_entry", locale: locale)
    }
}
