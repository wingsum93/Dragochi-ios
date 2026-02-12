//
//  MainStore.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import Combine

@MainActor
final class MainStore: ObservableObject {
    struct State: Equatable {
        var selectedGameID: UUID?
        var selectedPlatform: Platform = .pc
        var selectedFriendIDs: Set<UUID> = []
        var resumeLastSetup: Bool = true
        var isRunning: Bool = false
        var elapsedSeconds: Int = 0
        var currentSessionID: UUID?
        var runningStartAt: Date?
        var games: [GameEntity] = []
        var friends: [FriendEntity] = []
        var gameCards: [GameCardModel] = []
        var teammateChips: [TeammateChipModel] = []
        var pendingAddSessionDraft: AddSessionDraft?
        var errorMessage: String?
    }

    enum Action {
        case onAppear
        case startStopTapped
        case selectGame(UUID)
        case selectPlatform(Platform)
        case toggleFriend(UUID)
        case toggleResume(Bool)
        case tick
        case openAddSession
        case clearPendingDraft
    }

    @Published private(set) var state = State()

    private let sessionRepository: SessionRepository
    private let gameRepository: GameRepository
    private let friendRepository: FriendRepository

    init(dependencies: AppDependencies) {
        self.sessionRepository = dependencies.sessionRepository
        self.gameRepository = dependencies.gameRepository
        self.friendRepository = dependencies.friendRepository
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            loadInitialData()
        case .startStopTapped:
            handleStartStop()
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
        case .toggleResume(let isOn):
            state.resumeLastSetup = isOn
        case .tick:
            guard state.isRunning, let startAt = state.runningStartAt else { return }
            state.elapsedSeconds = max(0, Int(Date().timeIntervalSince(startAt)))
        case .openAddSession:
            state.pendingAddSessionDraft = buildDraft(
                sessionID: nil,
                startAt: Date(),
                endAt: Date()
            )
        case .clearPendingDraft:
            state.pendingAddSessionDraft = nil
        }
    }

    private func loadInitialData() {
        do {
            var games = try gameRepository.fetchAll()
            if games.isEmpty {
                games = try seedGames()
            }
            var friends = try friendRepository.fetchAll()
            if friends.isEmpty {
                friends = try seedFriends()
            }

            state.games = games
            state.friends = friends
            if state.selectedGameID == nil {
                state.selectedGameID = games.first?.id
            }
            state.gameCards = makeGameCards(from: games)
            state.teammateChips = makeTeammateChips(from: friends)
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func handleStartStop() {
        if state.isRunning {
            guard let sessionID = state.currentSessionID, let startAt = state.runningStartAt else { return }
            let endAt = Date()
            let session = SessionEntity(
                id: sessionID,
                startAt: startAt,
                endAt: endAt,
                platform: state.selectedPlatform,
                gameID: state.selectedGameID,
                note: nil,
                friendIDs: Array(state.selectedFriendIDs)
            )
            do {
                _ = try sessionRepository.update(session)
                state.isRunning = false
                state.elapsedSeconds = max(0, Int(endAt.timeIntervalSince(startAt)))
                state.pendingAddSessionDraft = buildDraft(
                    sessionID: sessionID,
                    startAt: startAt,
                    endAt: endAt
                )
            } catch {
                state.errorMessage = error.localizedDescription
            }
        } else {
            let startAt = Date()
            do {
                let created = try sessionRepository.create(
                    startAt: startAt,
                    endAt: nil,
                    platform: state.selectedPlatform,
                    gameID: state.selectedGameID,
                    note: nil,
                    friendIDs: Array(state.selectedFriendIDs)
                )
                state.currentSessionID = created.id
                state.runningStartAt = startAt
                state.isRunning = true
                state.elapsedSeconds = 0
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }

    private func buildDraft(sessionID: UUID?, startAt: Date, endAt: Date) -> AddSessionDraft {
        AddSessionDraft(
            id: UUID(),
            sessionID: sessionID,
            startAt: startAt,
            endAt: endAt,
            selectedGameID: state.selectedGameID,
            selectedPlatform: state.selectedPlatform,
            selectedFriendIDs: Array(state.selectedFriendIDs),
            note: ""
        )
    }

    private func seedGames() throws -> [GameEntity] {
        let seed: [(String, String)] = [
            ("Valorant", "https://www.figma.com/api/mcp/asset/5e99ed29-61aa-429d-9859-4ac4ee9efaa0"),
            ("LoL", "https://www.figma.com/api/mcp/asset/c2898203-26fd-4144-8c9c-086806a4a809"),
            ("Genshin", "https://www.figma.com/api/mcp/asset/1b2b8dae-8c5c-4f6f-9a74-b1dbf1f7d174")
        ]
        return try seed.map { name, icon in
            try gameRepository.create(name: name, icon: icon)
        }
    }

    private func seedFriends() throws -> [FriendEntity] {
        let names = [
            "Mason", "Kai", "Noah", "Leo", "Aiden", "Ryan", "Evan", "Jude",
            "Liam", "Owen", "Ava", "Mia", "Luna", "Ivy", "Nora"
        ]
        return try names.map { name in
            try friendRepository.create(name: name, handle: nil)
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
