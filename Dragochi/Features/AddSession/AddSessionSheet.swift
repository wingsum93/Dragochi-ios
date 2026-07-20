//
//  AddSessionSheet.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

struct AddSessionSheet: View {
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

#if DEBUG
#Preview("Add Session Sheet - Manual Entry") {
    AddSessionSheet(viewModel: AddSessionSheetPreview.makeViewModel())
}

@MainActor
private enum AddSessionSheetPreview {
    private static let valorantID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private static let lolID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private static let apexID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    private static let masonID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1")!
    private static let avaID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaab1")!

    static func makeViewModel() -> AddSessionViewModel {
        let games = [
            GameEntity(id: valorantID, name: "Valorant", imageAssetName: "volarant", remoteID: "valorant"),
            GameEntity(id: lolID, name: "LOL", imageAssetName: "lol", remoteID: "lol"),
            GameEntity(id: apexID, name: "Apex Legends", imageAssetName: "apex", remoteID: "apex")
        ]
        let friends = makeFriends()
        let sessions = makeArrangeSessions(friends: friends)
        let sessionRepository = FakeSessionRepository(sessions: sessions)
        let gameRepository = FakeGameRepository(games: games)
        let enabledGameSelectionRepository = FakeEnabledGameSelectionRepository(
            enabledRemoteIDs: Set(games.compactMap(\.remoteID))
        )
        let gameCatalogSyncService = GameCatalogSyncService(
            gameRepository: gameRepository,
            enabledSelectionRepository: enabledGameSelectionRepository,
            catalogService: PreviewGameCatalogService(catalog: games.map {
                CatalogGame(id: $0.remoteID ?? $0.id.uuidString, name: $0.name, imageAssetName: $0.imageAssetName)
            }),
            defaults: UserDefaults(suiteName: "AddSessionSheetPreview.\(UUID().uuidString)") ?? .standard
        )
        let startAt = Date(timeIntervalSinceReferenceDate: 0)

        return AddSessionViewModel(
            sessionRepository: sessionRepository,
            gameRepository: gameRepository,
            enabledGameSelectionRepository: enabledGameSelectionRepository,
            friendRepository: FakeFriendRepository(friends: friends),
            gameArrangeManager: GameArrangeManager(sessionRepository: sessionRepository),
            friendListArrangeManager: FriendListArrangeManager(
                sessionRepository: sessionRepository,
                friendRepository: FakeFriendRepository(friends: friends)
            ),
            gameCatalogSyncService: gameCatalogSyncService,
            auditLogger: PreviewAuditLogger(),
            draft: AddSessionDraft(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                mode: .manualEntry,
                sessionID: nil,
                startAt: startAt,
                endAt: startAt.addingTimeInterval(8_075),
                selectedGameID: valorantID,
                selectedPlatform: .pc,
                selectedFriendIDs: [masonID, avaID],
                note: ""
            )
        )
    }

    private static func makeFriends() -> [FriendEntity] {
        [
            FriendEntity(id: masonID, name: "Mason", avatarAssetName: "M1"),
            FriendEntity(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2")!, name: "Kai", avatarAssetName: "M2"),
            FriendEntity(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3")!, name: "Noah", avatarAssetName: "M3"),
            FriendEntity(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa4")!, name: "Leo", avatarAssetName: "M4"),
            FriendEntity(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa5")!, name: "Aiden", avatarAssetName: "M5"),
            FriendEntity(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa6")!, name: "Ryan", avatarAssetName: "M6"),
            FriendEntity(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa7")!, name: "Evan", avatarAssetName: "M7"),
            FriendEntity(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa8")!, name: "Jude", avatarAssetName: "M8"),
            FriendEntity(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa9")!, name: "Liam", avatarAssetName: "M9"),
            FriendEntity(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa10")!, name: "Owen", avatarAssetName: "M10"),
            FriendEntity(id: avaID, name: "Ava", avatarAssetName: "F1"),
            FriendEntity(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaab2")!, name: "Mia", avatarAssetName: "F2"),
            FriendEntity(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaab3")!, name: "Luna", avatarAssetName: "F3"),
            FriendEntity(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaab4")!, name: "Ivy", avatarAssetName: "F4"),
            FriendEntity(id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaab5")!, name: "Nora", avatarAssetName: "F5")
        ]
    }

    private static func makeArrangeSessions(friends: [FriendEntity]) -> [SessionEntity] {
        let baseDate = Date(timeIntervalSinceReferenceDate: 0)
        let friendSessions = friends.enumerated().map { index, friend in
            SessionEntity(
                startAt: baseDate.addingTimeInterval(TimeInterval(-3_600 - index)),
                endAt: baseDate.addingTimeInterval(TimeInterval(-index)),
                durationSeconds: 15_000 - index,
                platform: .pc,
                gameID: nil,
                friendIDs: [friend.id]
            )
        }
        let gameSessions = [
            SessionEntity(
                startAt: baseDate.addingTimeInterval(-600),
                endAt: baseDate,
                durationSeconds: 600,
                platform: .pc,
                gameID: valorantID
            ),
            SessionEntity(
                startAt: baseDate.addingTimeInterval(-1_800),
                endAt: baseDate.addingTimeInterval(-900),
                durationSeconds: 900,
                platform: .pc,
                gameID: lolID
            ),
            SessionEntity(
                startAt: baseDate.addingTimeInterval(-2_400),
                endAt: baseDate.addingTimeInterval(-1_900),
                durationSeconds: 500,
                platform: .pc,
                gameID: apexID
            )
        ]

        return gameSessions + friendSessions
    }
}

@MainActor
private struct PreviewGameCatalogService: GameCatalogService {
    let catalog: [CatalogGame]

    func fallbackCatalog() -> [CatalogGame] {
        catalog
    }

    func fetchLatestCatalog() async throws -> [CatalogGame] {
        catalog
    }
}

@MainActor
private struct PreviewAuditLogger: AuditLogging {
    func log(action: AuditAction, outcome: AuditOutcome, metadata: [String: String]) {}
}
#endif
