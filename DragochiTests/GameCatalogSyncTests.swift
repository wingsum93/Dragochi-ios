//
//  GameCatalogSyncTests.swift
//  DragochiTests
//
//  Created by Codex on 15/2/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Dragochi

struct GameCatalogSyncTests {
    @Test
    @MainActor
    func refresh_removesStaleEnabledSelections() async throws {
        let container = try SwiftDataStack.makeInMemoryContainer()
        let modelContext = ModelContext(container)
        let gameRepository = SwiftDataGameRepository(modelContext: modelContext)
        let enabledRepository = SwiftDataEnabledGameSelectionRepository(modelContext: modelContext)

        let catalogService = StubGameCatalogService(
            fallback: [
                CatalogGame(id: "game_a", name: "Game A", imageAssetName: nil),
                CatalogGame(id: "game_b", name: "Game B", imageAssetName: nil)
            ],
            latest: [
                CatalogGame(id: "game_a", name: "Game A", imageAssetName: nil)
            ]
        )

        let syncService = GameCatalogSyncService(
            gameRepository: gameRepository,
            enabledSelectionRepository: enabledRepository,
            catalogService: catalogService,
            defaults: UserDefaults(suiteName: "dragochi.tests.catalog.\(UUID().uuidString)") ?? .standard
        )

        _ = try syncService.seedFromFallbackIfNeeded()
        #expect(try enabledRepository.fetchEnabledRemoteIDs() == Set(["game_a", "game_b"]))

        _ = try await syncService.refreshFromRemote()
        #expect(try enabledRepository.fetchEnabledRemoteIDs() == Set(["game_a"]))
    }

    @Test
    @MainActor
    func refresh_keepsSessionsAndSessionLinkedGameRecords() async throws {
        let container = try SwiftDataStack.makeInMemoryContainer()
        let modelContext = ModelContext(container)
        let gameRepository = SwiftDataGameRepository(modelContext: modelContext)
        let sessionRepository = SwiftDataSessionRepository(modelContext: modelContext)
        let enabledRepository = SwiftDataEnabledGameSelectionRepository(modelContext: modelContext)

        let catalogService = StubGameCatalogService(
            fallback: [CatalogGame(id: "game_a", name: "Game A", imageAssetName: nil)],
            latest: []
        )

        let syncService = GameCatalogSyncService(
            gameRepository: gameRepository,
            enabledSelectionRepository: enabledRepository,
            catalogService: catalogService,
            defaults: UserDefaults(suiteName: "dragochi.tests.catalog.\(UUID().uuidString)") ?? .standard
        )

        _ = try syncService.seedFromFallbackIfNeeded()
        guard let game = try gameRepository.fetch(remoteID: "game_a") else {
            Issue.record("Expected seeded game for game_a")
            return
        }

        _ = try sessionRepository.create(
            startAt: Date(timeIntervalSince1970: 1_700_000_000),
            endAt: Date(timeIntervalSince1970: 1_700_000_060),
            platform: .pc,
            gameID: game.id,
            durationSeconds: nil,
            note: nil,
            friendIDs: []
        )

        _ = try await syncService.refreshFromRemote()

        let sessions = try sessionRepository.fetchEnded(between: .distantPast, and: .distantFuture)
        #expect(sessions.count == 1)
        #expect(sessions.first?.gameID == game.id)
        #expect(try gameRepository.fetch(remoteID: "game_a") != nil)
        #expect(try enabledRepository.fetchEnabledRemoteIDs().isEmpty)
    }

    @Test
    @MainActor
    func addSessionStore_showsOnlyAddCardWhenNoEnabledGames() async throws {
        let container = try SwiftDataStack.makeInMemoryContainer()
        let dependencies = AppDependencies(modelContext: ModelContext(container))

        _ = try dependencies.gameCatalogSyncService.seedFromFallbackIfNeeded()
        let enabledIDs = try dependencies.enabledGameSelectionRepository.fetchEnabledRemoteIDs()
        for remoteID in enabledIDs {
            try dependencies.enabledGameSelectionRepository.disable(remoteID: remoteID)
        }

        let draft = AddSessionDraft(
            id: UUID(),
            mode: .manualEntry,
            sessionID: nil,
            startAt: Date(),
            endAt: Date(),
            selectedGameID: nil,
            selectedPlatform: .pc,
            selectedFriendIDs: [],
            note: ""
        )

        let viewModel = AddSessionViewModel(dependencies: dependencies, draft: draft)
        viewModel.send(.onAppear)

        #expect(viewModel.state.gameCards.count == 1)
        #expect(viewModel.state.gameCards.first?.id == "add")
    }
}

@MainActor
private final class StubGameCatalogService: GameCatalogService {
    let fallback: [CatalogGame]
    let latest: [CatalogGame]

    init(fallback: [CatalogGame], latest: [CatalogGame]) {
        self.fallback = fallback
        self.latest = latest
    }

    func fallbackCatalog() -> [CatalogGame] {
        fallback
    }

    func fetchLatestCatalog() async throws -> [CatalogGame] {
        latest
    }
}
