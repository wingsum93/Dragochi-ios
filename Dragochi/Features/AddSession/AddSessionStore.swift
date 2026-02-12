//
//  AddSessionStore.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import Combine

struct AddSessionDraft: Identifiable, Hashable {
    let id: UUID
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
        case selectPlatform(Platform)
        case toggleFriend(UUID)
        case updateNote(String)
        case saveTapped
        case discardTapped
    }

    @Published private(set) var state: State

    private let sessionRepository: SessionRepository
    private let gameRepository: GameRepository
    private let friendRepository: FriendRepository
    private let onClose: () -> Void

    init(
        dependencies: AppDependencies,
        draft: AddSessionDraft,
        onClose: @escaping () -> Void = {}
    ) {
        self.sessionRepository = dependencies.sessionRepository
        self.gameRepository = dependencies.gameRepository
        self.friendRepository = dependencies.friendRepository
        self.onClose = onClose
        self.state = State(
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
            let games = try gameRepository.fetchAll()
            let friends = try friendRepository.fetchAll()
            state.games = games
            state.friends = friends
            state.gameCards = makeGameCards(from: games)
            state.teammateChips = makeTeammateChips(from: friends)
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func saveSession() {
        state.isSaving = true
        defer { state.isSaving = false }

        let endAt = state.endAt
        let session = SessionEntity(
            id: state.sessionID ?? UUID(),
            startAt: state.startAt,
            endAt: endAt,
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

    private func makeGameCards(from games: [GameEntity]) -> [GameCardModel] {
        let cards = games.map { game in
            GameCardModel(
                id: game.id.uuidString,
                title: game.name,
                imageURL: game.icon.flatMap { URL(string: $0) }
            )
        }
        return cards + [GameCardModel(id: "add", title: "Add", imageURL: nil)]
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
