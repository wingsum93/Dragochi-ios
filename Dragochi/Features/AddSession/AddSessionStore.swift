//
//  AddSessionStore.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import Combine

enum AddSessionMode: String, Codable, Hashable {
    case manualEntry
    case preStartSetup
}

struct SessionSetupInput: Codable, Hashable {
    let selectedGameID: UUID
    let selectedPlatform: Platform
    let selectedFriendIDs: [UUID]
    let note: String
}

struct AddSessionDraft: Identifiable, Hashable {
    let id: UUID
    let mode: AddSessionMode
    let sessionID: UUID?
    let startAt: Date
    let endAt: Date
    let selectedGameID: UUID?
    let selectedPlatform: Platform
    let selectedFriendIDs: [UUID]
    let note: String
}

@MainActor
final class AddSessionStore: ObservableObject {
    struct State: Equatable {
        var mode: AddSessionMode
        var sessionID: UUID?
        var startAt: Date
        var endAt: Date
        var selectedGameID: UUID?
        var selectedPlatform: Platform
        var selectedFriendIDs: Set<UUID> = []
        var note: String
        var games: [GameEntity] = []
        var friends: [FriendEntity] = []
        var gameCards: [GameCardModel] = []
        var teammateChips: [TeammateChipModel] = []
        var isSaving: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case onAppear
        case selectGame(UUID)
        case addGameTapped
        case selectPlatform(Platform)
        case toggleFriend(UUID)
        case updateNote(String)
        case saveTapped
        case discardTapped
    }

    @Published private(set) var state: State

    private let sessionRepository: SessionRepository
    private let gameRepository: GameRepository
    private let enabledGameSelectionRepository: EnabledGameSelectionRepository
    private let friendRepository: FriendRepository
    private let gameCatalogSyncService: GameCatalogSyncService
    private let onSetupConfirmed: ((SessionSetupInput) -> Void)?
    private let onOpenGameSettings: () -> Void
    private let onClose: () -> Void

    init(
        dependencies: AppDependencies,
        draft: AddSessionDraft,
        onSetupConfirmed: ((SessionSetupInput) -> Void)? = nil,
        onOpenGameSettings: @escaping () -> Void = {},
        onClose: @escaping () -> Void = {}
    ) {
        self.sessionRepository = dependencies.sessionRepository
        self.gameRepository = dependencies.gameRepository
        self.enabledGameSelectionRepository = dependencies.enabledGameSelectionRepository
        self.friendRepository = dependencies.friendRepository
        self.gameCatalogSyncService = dependencies.gameCatalogSyncService
        self.onSetupConfirmed = onSetupConfirmed
        self.onOpenGameSettings = onOpenGameSettings
        self.onClose = onClose
        self.state = State(
            mode: draft.mode,
            sessionID: draft.sessionID,
            startAt: draft.startAt,
            endAt: draft.endAt,
            selectedGameID: draft.selectedGameID,
            selectedPlatform: draft.selectedPlatform,
            selectedFriendIDs: Set(draft.selectedFriendIDs),
            note: draft.note
        )
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            loadData()
        case .selectGame(let id):
            state.selectedGameID = id
        case .addGameTapped:
            onOpenGameSettings()
        case .selectPlatform(let platform):
            state.selectedPlatform = platform
        case .toggleFriend(let id):
            if state.selectedFriendIDs.contains(id) {
                state.selectedFriendIDs.remove(id)
            } else {
                state.selectedFriendIDs.insert(id)
            }
        case .updateNote(let note):
            state.note = note
        case .saveTapped:
            saveSession()
        case .discardTapped:
            onClose()
        }
    }

    private func loadData() {
        do {
            _ = try gameCatalogSyncService.seedFromFallbackIfNeeded()
            let games = try gameRepository.fetchAll()
            let enabledRemoteIDs = try enabledGameSelectionRepository.fetchEnabledRemoteIDs()
            let friends = try friendRepository.fetchAll()
            state.games = games
            state.friends = friends
            state.gameCards = makeGameCards(from: games, enabledRemoteIDs: enabledRemoteIDs)
            state.teammateChips = makeTeammateChips(from: friends)
            state.errorMessage = nil

            if !ProcessInfo.processInfo.arguments.contains("-ui-testing") {
                Task { [weak self] in
                    await self?.refreshFromRemote()
                }
            }
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func refreshFromRemote() async {
        do {
            _ = try await gameCatalogSyncService.refreshFromRemote()
            let refreshedGames = try gameRepository.fetchAll()
            let refreshedEnabled = try enabledGameSelectionRepository.fetchEnabledRemoteIDs()
            state.games = refreshedGames
            state.gameCards = makeGameCards(from: refreshedGames, enabledRemoteIDs: refreshedEnabled)
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func saveSession() {
        if state.mode == .preStartSetup {
            guard let selectedGameID = state.selectedGameID else {
                state.errorMessage = "Please select a game before starting."
                return
            }

            let setup = SessionSetupInput(
                selectedGameID: selectedGameID,
                selectedPlatform: state.selectedPlatform,
                selectedFriendIDs: Array(state.selectedFriendIDs),
                note: state.note
            )
            onSetupConfirmed?(setup)
            onClose()
            return
        }

        state.isSaving = true
        defer { state.isSaving = false }

        let endAt = state.endAt
        let durationSeconds = max(0, Int(endAt.timeIntervalSince(state.startAt)))
        let session = SessionEntity(
            id: state.sessionID ?? UUID(),
            startAt: state.startAt,
            endAt: endAt,
            durationSeconds: durationSeconds,
            platform: state.selectedPlatform,
            gameID: state.selectedGameID,
            note: state.note.isEmpty ? nil : state.note,
            friendIDs: Array(state.selectedFriendIDs)
        )

        do {
            if state.sessionID == nil {
                _ = try sessionRepository.create(
                    startAt: session.startAt,
                    endAt: session.endAt,
                    platform: session.platform,
                    gameID: session.gameID,
                    durationSeconds: session.durationSeconds,
                    note: session.note,
                    friendIDs: session.friendIDs
                )
            } else {
                _ = try sessionRepository.update(session)
            }
            onClose()
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func makeGameCards(from games: [GameEntity], enabledRemoteIDs: Set<String>) -> [GameCardModel] {
        let cards = games
            .filter { game in
                guard let remoteID = game.remoteID else { return false }
                return enabledRemoteIDs.contains(remoteID)
            }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .map { game in
            GameCardModel(
                id: game.id.uuidString,
                title: game.name,
                imageAssetName: game.imageAssetName
            )
        }

        if cards.isEmpty {
            return [GameCardModel(id: "add", title: "Add", imageAssetName: nil)]
        }

        return cards + [GameCardModel(id: "add", title: "Add", imageAssetName: nil)]
    }

    private func makeTeammateChips(from friends: [FriendEntity]) -> [TeammateChipModel] {
        let assetNames = [
            "M1", "M2", "M3", "M4", "M5", "M6", "M7", "M8", "M9", "M10",
            "F1", "F2", "F3", "F4", "F5"
        ]
        return friends.enumerated().map { index, friend in
            let assetName = index < assetNames.count ? assetNames[index] : nil
            return TeammateChipModel(
                id: friend.id.uuidString,
                name: friend.name,
                avatarAssetName: assetName
            )
        }
    }
}
