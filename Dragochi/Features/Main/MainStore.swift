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
    private struct CanonicalGame {
        let name: String
        let imageAssetName: String
        let legacyNames: [String]
    }

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
    private let canonicalGames: [CanonicalGame] = [
        .init(name: "Apex Legends", imageAssetName: "apex", legacyNames: []),
        .init(name: "LOL", imageAssetName: "lol", legacyNames: ["league of legends", "lol"]),
        .init(name: "World War Z", imageAssetName: "wwz", legacyNames: ["wwz"]),
        .init(name: "Clash Royale", imageAssetName: "clash_royale", legacyNames: ["clash royale", "clash_royale"]),
        .init(name: "Valorant", imageAssetName: "volarant", legacyNames: ["valorant"])
    ]

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
            let games = try syncGamesWithAssets()
            var friends = try friendRepository.fetchAll()
            if friends.isEmpty {
                friends = try seedFriends()
            }

            state.games = games
            state.friends = friends
            if let selectedGameID = state.selectedGameID,
               games.contains(where: { $0.id == selectedGameID }) == false {
                state.selectedGameID = games.first?.id
            } else if state.selectedGameID == nil {
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

    private func syncGamesWithAssets() throws -> [GameEntity] {
        var games = try gameRepository.fetchAll()

        for canonical in canonicalGames {
            if let index = games.firstIndex(where: { $0.imageAssetName == canonical.imageAssetName }) {
                var existing = games[index]
                if existing.name != canonical.name || existing.imageAssetName != canonical.imageAssetName {
                    existing.name = canonical.name
                    existing.imageAssetName = canonical.imageAssetName
                    games[index] = try gameRepository.upsert(existing)
                }
                continue
            }

            if let index = games.firstIndex(where: { isCanonicalMatch(gameName: $0.name, canonical: canonical) }) {
                var existing = games[index]
                if existing.name != canonical.name || existing.imageAssetName != canonical.imageAssetName {
                    existing.name = canonical.name
                    existing.imageAssetName = canonical.imageAssetName
                    games[index] = try gameRepository.upsert(existing)
                }
                continue
            }

            let created = try gameRepository.create(
                name: canonical.name,
                imageAssetName: canonical.imageAssetName
            )
            games.append(created)
        }

        return try removeLegacyGames(from: games)
    }

    private func removeLegacyGames(from games: [GameEntity]) throws -> [GameEntity] {
        var remainingGames = games
        let legacyGames = remainingGames.filter {
            normalizeGameName($0.name) == "genshin" || $0.imageAssetName == "genshin"
        }

        for legacyGame in legacyGames {
            try gameRepository.delete(id: legacyGame.id)
        }

        remainingGames.removeAll {
            normalizeGameName($0.name) == "genshin" || $0.imageAssetName == "genshin"
        }
        return remainingGames
    }

    private func isCanonicalMatch(gameName: String, canonical: CanonicalGame) -> Bool {
        let normalizedName = normalizeGameName(gameName)
        if normalizedName == normalizeGameName(canonical.name) {
            return true
        }
        return canonical.legacyNames.contains { normalizeGameName($0) == normalizedName }
    }

    private func normalizeGameName(_ name: String) -> String {
        name
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
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
                imageAssetName: game.imageAssetName
            )
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
