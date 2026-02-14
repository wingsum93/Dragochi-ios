//
//  MVIStoresTests.swift
//  DragochiTests
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Dragochi

struct MVIStoresTests {
    @Test
    func mainStore_startStopFlow() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))

            _ = try dependencies.gameRepository.create(name: "Genshin", imageAssetName: "genshin")
            _ = try dependencies.gameRepository.create(name: "League of Legends", imageAssetName: "lol")

            let store = MainStore(dependencies: dependencies)

            store.send(.onAppear)
            #expect(!store.state.games.isEmpty)
            let gameAssets = Set(store.state.games.compactMap(\.imageAssetName))
            #expect(gameAssets.isSuperset(of: ["apex", "lol", "wwz", "clash_royale", "volarant"]))
            #expect(store.state.games.contains(where: { $0.name == "Genshin" }) == false)
            #expect(store.state.games.first(where: { $0.imageAssetName == "lol" })?.name == "LOL")

            store.send(.startStopTapped)
            #expect(store.state.isRunning)

            store.send(.tick)
            store.send(.startStopTapped)
            #expect(!store.state.isRunning)
            #expect(store.state.pendingAddSessionDraft != nil)
        }
    }

    @Test
    func addSessionStore_createsSession() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            let draft = AddSessionDraft(
                id: UUID(),
                sessionID: nil,
                startAt: Date(timeIntervalSince1970: 1_700_000_000),
                endAt: Date(timeIntervalSince1970: 1_700_000_600),
                selectedGameID: nil,
                selectedPlatform: .pc,
                selectedFriendIDs: [],
                note: "test"
            )
            var didClose = false
            let store = AddSessionStore(
                dependencies: dependencies,
                draft: draft,
                onClose: { didClose = true }
            )

            store.send(.onAppear)
            store.send(.saveTapped)

            let sessions = try dependencies.sessionRepository.fetchEnded(
                between: Date(timeIntervalSince1970: 1_699_999_000),
                and: Date(timeIntervalSince1970: 1_700_001_000)
            )
            #expect(!sessions.isEmpty)
            #expect(didClose)
        }
    }

    @Test
    func historyStore_buildsSections() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))

            _ = try dependencies.sessionRepository.create(
                startAt: Date(timeIntervalSince1970: 1_700_000_000),
                endAt: Date(timeIntervalSince1970: 1_700_000_600),
                platform: .pc,
                gameID: nil,
                note: nil,
                friendIDs: []
            )

            let store = HistoryStore(dependencies: dependencies)
            store.send(.onAppear)
            #expect(!store.state.sections.isEmpty)
            #expect(store.state.totalPlaytimeSeconds > 0)
        }
    }

    @Test
    func statsStore_loadsReport() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            let store = StatsStore(dependencies: dependencies)

            store.send(.onAppear)
            #expect(store.state.report != nil)
        }
    }

    @Test
    func settingsStore_toggleAndBackup() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            let store = SettingsStore(dependencies: dependencies)

            store.send(.toggleICloud(true))
            #expect(store.state.isICloudSyncOn)

            store.send(.exportTapped)
            #expect(store.state.lastBackupDate != nil)
        }
    }
}
