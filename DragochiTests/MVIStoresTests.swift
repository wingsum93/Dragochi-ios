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
    func mainStore_trackingPauseResumeAndRestoreFlow() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))

            var current = Date(timeIntervalSince1970: 1_700_000_000)
            let store = MainStore(dependencies: dependencies, now: { current })

            store.send(.onAppear)
            let gameAssets = Set(store.state.games.compactMap(\.imageAssetName))
            #expect(gameAssets.isSuperset(of: ["apex", "lol", "wwz", "clash_royale", "volarant"]))

            store.send(.startTapped)
            #expect(store.state.pendingAddSessionDraft?.mode == .preStartSetup)

            guard let selectedGameID = store.state.games.first?.id else {
                Issue.record("Expected at least one game to be available.")
                return
            }

            let setup = SessionSetupInput(
                selectedGameID: selectedGameID,
                selectedPlatform: .pc,
                selectedFriendIDs: [],
                note: "focus run"
            )
            store.send(.preStartSetupConfirmed(setup))
            #expect(store.state.trackingStatus == .running)

            current = current.addingTimeInterval(15)
            store.send(.tick)
            #expect(store.state.elapsedSeconds == 15)

            store.send(.pauseResumeTapped)
            #expect(store.state.trackingStatus == .paused)
            #expect(store.state.elapsedSeconds == 15)
            let snapshotData = store.state.trackingSnapshotData
            #expect(snapshotData != nil)

            current = current.addingTimeInterval(20)
            store.send(.tick)
            #expect(store.state.elapsedSeconds == 15)

            let restoredStore = MainStore(dependencies: dependencies, now: { current })
            restoredStore.send(.onAppear)
            restoredStore.send(.restoreTrackingSnapshot(snapshotData))
            #expect(restoredStore.state.trackingStatus == .paused)
            #expect(restoredStore.state.currentSessionID == store.state.currentSessionID)

            restoredStore.send(.pauseResumeTapped)
            #expect(restoredStore.state.trackingStatus == .running)

            current = current.addingTimeInterval(10)
            restoredStore.send(.tick)
            #expect(restoredStore.state.elapsedSeconds == 25)

            restoredStore.send(.stopTapped)
            #expect(restoredStore.state.trackingStatus == .idle)
            #expect(restoredStore.state.trackingSnapshotData == nil)

            let sessions = try dependencies.sessionRepository.fetchEnded(
                between: Date(timeIntervalSince1970: 1_699_999_000),
                and: Date(timeIntervalSince1970: 1_700_001_000)
            )
            #expect(sessions.count == 1)
            #expect(sessions.first?.durationSeconds == 25)
        }
    }

    @Test
    func addSessionStore_createsManualSession() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            let draft = AddSessionDraft(
                id: UUID(),
                mode: .manualEntry,
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
    func addSessionStore_preStartAllowsZeroPeople() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            let game = try dependencies.gameRepository.create(name: "Apex Legends", imageAssetName: "apex")

            let draft = AddSessionDraft(
                id: UUID(),
                mode: .preStartSetup,
                sessionID: nil,
                startAt: Date(),
                endAt: Date(),
                selectedGameID: game.id,
                selectedPlatform: .pc,
                selectedFriendIDs: [],
                note: ""
            )
            var didClose = false
            var receivedSetup: SessionSetupInput?

            let store = AddSessionStore(
                dependencies: dependencies,
                draft: draft,
                onSetupConfirmed: { setup in receivedSetup = setup },
                onClose: { didClose = true }
            )

            store.send(.onAppear)
            store.send(.saveTapped)

            #expect(receivedSetup != nil)
            #expect(receivedSetup?.selectedFriendIDs.isEmpty == true)
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
                durationSeconds: nil,
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
