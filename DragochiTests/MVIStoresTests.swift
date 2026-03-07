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
    func mainStore_loadsLatestEndedSessionForResumeCard() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))

            let older = try dependencies.sessionRepository.create(
                startAt: Date(timeIntervalSince1970: 1_700_000_000),
                endAt: Date(timeIntervalSince1970: 1_700_000_300),
                platform: .pc,
                gameID: nil,
                durationSeconds: nil,
                note: nil,
                friendIDs: []
            )

            let newer = try dependencies.sessionRepository.create(
                startAt: Date(timeIntervalSince1970: 1_700_000_400),
                endAt: Date(timeIntervalSince1970: 1_700_000_900),
                platform: .mobile,
                gameID: nil,
                durationSeconds: nil,
                note: nil,
                friendIDs: []
            )

            let store = MainStore(dependencies: dependencies)
            store.send(.onAppear)

            #expect(older.id != newer.id)
            #expect(store.state.latestEndedSession?.id == newer.id)
        }
    }

    @Test
    func mainStore_noEndedSessionsKeepsLatestEndedSessionNil() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            let store = MainStore(dependencies: dependencies)

            store.send(.onAppear)

            #expect(store.state.latestEndedSession == nil)
            #expect(store.state.friends.isEmpty)
        }
    }

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

            store.send(.startTapped(resumeLastSetupEnabled: false))
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
    func mainStore_startTappedWithResumeEnabledStartsTrackingFromLatestSession() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            var current = Date(timeIntervalSince1970: 1_700_000_000)

            let game = try dependencies.gameRepository.create(name: "Apex Legends", imageAssetName: "apex", remoteID: nil)
            let activeFriend = try dependencies.friendRepository.create(
                name: "Aiden",
                handle: nil,
                avatarAssetName: nil,
                isActive: true
            )
            let inactiveFriend = try dependencies.friendRepository.create(
                name: "Kai",
                handle: nil,
                avatarAssetName: nil,
                isActive: false
            )

            _ = try dependencies.sessionRepository.create(
                startAt: current.addingTimeInterval(-400),
                endAt: current.addingTimeInterval(-100),
                platform: .console,
                gameID: game.id,
                durationSeconds: nil,
                note: "old note",
                friendIDs: [activeFriend.id, inactiveFriend.id]
            )

            let store = MainStore(dependencies: dependencies, now: { current })
            store.send(.onAppear)
            store.send(.startTapped(resumeLastSetupEnabled: true))

            #expect(store.state.trackingStatus == .running)
            #expect(store.state.pendingAddSessionDraft == nil)
            #expect(store.state.activeSetup?.selectedGameID == game.id)
            #expect(store.state.activeSetup?.selectedPlatform == .console)
            #expect(store.state.activeSetup?.selectedFriendIDs == [activeFriend.id])
            #expect(store.state.activeSetup?.note == "")

            guard let currentSessionID = store.state.currentSessionID else {
                Issue.record("Expected active session ID after quick start.")
                return
            }

            let runningSession = try dependencies.sessionRepository.fetch(id: currentSessionID)
            #expect(runningSession?.gameID == game.id)
            #expect(runningSession?.platform == .console)
            #expect(runningSession?.friendIDs == [activeFriend.id])
            #expect(runningSession?.endAt == nil)
            #expect(runningSession?.note == nil)
        }
    }

    @Test
    func mainStore_startTappedWithResumeEnabledFallsBackToNormalFlowWhenNoGame() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            let current = Date(timeIntervalSince1970: 1_700_000_000)

            _ = try dependencies.sessionRepository.create(
                startAt: current.addingTimeInterval(-400),
                endAt: current.addingTimeInterval(-100),
                platform: .pc,
                gameID: nil,
                durationSeconds: nil,
                note: nil,
                friendIDs: []
            )

            let store = MainStore(dependencies: dependencies, now: { current })
            store.send(.onAppear)
            store.send(.startTapped(resumeLastSetupEnabled: true))

            #expect(store.state.trackingStatus == .idle)
            #expect(store.state.currentSessionID == nil)
            #expect(store.state.pendingAddSessionDraft?.mode == .preStartSetup)
        }
    }

    @Test
    func addSessionStore_preStartAllowsZeroPeople() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            let game = try dependencies.gameRepository.create(name: "Apex Legends", imageAssetName: "apex", remoteID: nil)

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
    func addSessionStore_showsNoTeammateChipsWhenNoActiveFriends() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
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

            let store = AddSessionStore(dependencies: dependencies, draft: draft)
            store.send(.onAppear)

            #expect(store.state.teammateChips.isEmpty)
        }
    }

    @Test
    func addSessionStore_usesPersistedFriendAvatarAsset() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            let friend = try dependencies.friendRepository.create(
                name: "Ava",
                handle: nil,
                avatarAssetName: "F2",
                isActive: true
            )
            let draft = AddSessionDraft(
                id: UUID(),
                mode: .manualEntry,
                sessionID: nil,
                startAt: Date(),
                endAt: Date(),
                selectedGameID: nil,
                selectedPlatform: .pc,
                selectedFriendIDs: [friend.id],
                note: ""
            )

            let store = AddSessionStore(dependencies: dependencies, draft: draft)
            store.send(.onAppear)

            #expect(store.state.teammateChips.count == 1)
            #expect(store.state.teammateChips.first?.avatarAssetName == "F2")
            #expect(store.state.selectedFriendIDs.contains(friend.id))
        }
    }

    @Test
    func friendSettingsStore_addEditDeleteAndValidation() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            let existing = try dependencies.friendRepository.create(
                name: "Mason",
                handle: nil,
                avatarAssetName: "M1",
                isActive: true
            )
            let store = FriendSettingsStore(dependencies: dependencies)

            store.send(.onAppear)
            #expect(store.state.friends.count == 1)

            store.send(.addTapped)
            store.send(.updateEditingName("  mason  "))
            store.send(.saveEditingTapped)
            #expect(store.state.editValidationMessage != nil || store.state.editValidationMessageKey != nil)

            store.send(.updateEditingName("Ava"))
            store.send(.selectEditingAvatar("F4"))
            store.send(.saveEditingTapped)
            #expect(store.state.friends.count == 2)

            guard let addedFriend = store.state.friends.first(where: { $0.name == "Ava" }) else {
                Issue.record("Expected newly added friend.")
                return
            }
            #expect(addedFriend.avatarAssetName == "F4")
            #expect(addedFriend.isActive)

            store.send(.editTapped(existing.id))
            store.send(.updateEditingName("Mason Prime"))
            store.send(.selectEditingAvatar("M2"))
            store.send(.saveEditingTapped)
            #expect(store.state.friends.first(where: { $0.id == existing.id })?.name == "Mason Prime")
            #expect(store.state.friends.first(where: { $0.id == existing.id })?.avatarAssetName == "M2")

            store.send(.deleteTapped(existing.id))
            #expect(store.state.isShowingDeleteDialog)
            store.send(.confirmDeleteTapped)
            #expect(!store.state.friends.contains(where: { $0.id == existing.id }))

            let persisted = try dependencies.friendRepository.fetch(id: existing.id)
            #expect(persisted?.isActive == false)
        }
    }

    @Test
    func gameSettingsStore_doneTappedWithoutChangesClosesImmediately() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            var didClose = false
            let store = GameSettingsStore(
                dependencies: dependencies,
                onClose: { didClose = true },
                isUITesting: true
            )

            store.send(.onAppear)
            store.send(.doneTapped)

            #expect(didClose)
            #expect(!store.state.isShowingConfirmChangesDialog)
        }
    }

    @Test
    func gameSettingsStore_doneTappedWithChangesShowsDialogAndNoKeepsPage() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            var didClose = false
            let store = GameSettingsStore(
                dependencies: dependencies,
                onClose: { didClose = true },
                isUITesting: true
            )

            store.send(.onAppear)
            guard let remoteID = store.state.catalog.first?.id else {
                Issue.record("Expected catalog to contain at least one game.")
                return
            }

            let persistedBeforeToggle = try dependencies.enabledGameSelectionRepository.fetchEnabledRemoteIDs()

            store.send(.toggle(remoteID: remoteID))

            let persistedAfterToggle = try dependencies.enabledGameSelectionRepository.fetchEnabledRemoteIDs()
            #expect(persistedAfterToggle == persistedBeforeToggle)
            #expect(store.state.draftEnabledRemoteIDs != store.state.originalEnabledRemoteIDs)

            store.send(.doneTapped)
            #expect(store.state.isShowingConfirmChangesDialog)
            #expect(!didClose)

            store.send(.cancelSaveChanges)

            let persistedAfterCancel = try dependencies.enabledGameSelectionRepository.fetchEnabledRemoteIDs()
            #expect(!store.state.isShowingConfirmChangesDialog)
            #expect(persistedAfterCancel == persistedBeforeToggle)
            #expect(!didClose)
        }
    }

    @Test
    func gameSettingsStore_confirmSavePersistsDiffAndCloses() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            var didClose = false
            let store = GameSettingsStore(
                dependencies: dependencies,
                onClose: { didClose = true },
                isUITesting: true
            )

            store.send(.onAppear)
            guard let remoteID = store.state.catalog.first?.id else {
                Issue.record("Expected catalog to contain at least one game.")
                return
            }

            #expect(try dependencies.gameRepository.fetch(remoteID: remoteID) != nil)

            store.send(.toggle(remoteID: remoteID))
            store.send(.doneTapped)
            #expect(store.state.isShowingConfirmChangesDialog)

            store.send(.confirmSaveChanges)

            let persistedAfterConfirm = try dependencies.enabledGameSelectionRepository.fetchEnabledRemoteIDs()
            #expect(didClose)
            #expect(!store.state.isShowingConfirmChangesDialog)
            #expect(store.state.originalEnabledRemoteIDs == store.state.draftEnabledRemoteIDs)
            #expect(!persistedAfterConfirm.contains(remoteID))
            #expect(try dependencies.gameRepository.fetch(remoteID: remoteID) == nil)
        }
    }

    @Test
    func gameSettingsStore_backTappedClosesWithoutSavingDraftChanges() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            var didClose = false
            let store = GameSettingsStore(
                dependencies: dependencies,
                onClose: { didClose = true },
                isUITesting: true
            )

            store.send(.onAppear)
            guard let remoteID = store.state.catalog.first?.id else {
                Issue.record("Expected catalog to contain at least one game.")
                return
            }

            let persistedBeforeBack = try dependencies.enabledGameSelectionRepository.fetchEnabledRemoteIDs()
            store.send(.toggle(remoteID: remoteID))
            store.send(.backTapped)
            let persistedAfterBack = try dependencies.enabledGameSelectionRepository.fetchEnabledRemoteIDs()

            #expect(didClose)
            #expect(persistedAfterBack == persistedBeforeBack)
        }
    }

    @Test
    func historyStore_buildsSections() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))

            let alexID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
            let benID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
            let caraID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

            _ = try dependencies.friendRepository.upsert(
                FriendEntity(id: alexID, name: "Alex", handle: nil, avatarAssetName: nil, isActive: true)
            )
            _ = try dependencies.friendRepository.upsert(
                FriendEntity(id: benID, name: "Ben", handle: nil, avatarAssetName: nil, isActive: true)
            )
            _ = try dependencies.friendRepository.upsert(
                FriendEntity(id: caraID, name: "Cara", handle: nil, avatarAssetName: nil, isActive: true)
            )

            _ = try dependencies.sessionRepository.create(
                startAt: Date(timeIntervalSince1970: 1_700_000_000),
                endAt: Date(timeIntervalSince1970: 1_700_000_600),
                platform: .pc,
                gameID: nil,
                durationSeconds: nil,
                note: nil,
                friendIDs: []
            )
            _ = try dependencies.sessionRepository.create(
                startAt: Date(timeIntervalSince1970: 1_700_001_000),
                endAt: Date(timeIntervalSince1970: 1_700_001_900),
                platform: .pc,
                gameID: nil,
                durationSeconds: nil,
                note: nil,
                friendIDs: [alexID]
            )
            _ = try dependencies.sessionRepository.create(
                startAt: Date(timeIntervalSince1970: 1_700_002_000),
                endAt: Date(timeIntervalSince1970: 1_700_003_200),
                platform: .pc,
                gameID: nil,
                durationSeconds: nil,
                note: nil,
                friendIDs: [alexID, benID]
            )
            _ = try dependencies.sessionRepository.create(
                startAt: Date(timeIntervalSince1970: 1_700_004_000),
                endAt: Date(timeIntervalSince1970: 1_700_005_500),
                platform: .pc,
                gameID: nil,
                durationSeconds: nil,
                note: nil,
                friendIDs: [alexID, benID, caraID]
            )

            let store = HistoryStore(dependencies: dependencies)
            store.send(.onAppear)
            #expect(!store.state.sections.isEmpty)
            #expect(store.state.totalPlaytimeSeconds > 0)

            let rows = store.state.sections.flatMap(\.rows)
            #expect(rows.count == 4)

            let locale = Locale.current
            let expectedSoloText = L10n.string("text_teammates_solo", locale: locale)
            let expectedThreeFriendsText = L10n.format("text_history_friend_count_format", locale: locale, 3)

            #expect(rows.first(where: { $0.durationSeconds == 600 })?.friendInfoText == expectedSoloText)
            #expect(rows.first(where: { $0.durationSeconds == 900 })?.friendInfoText == "Alex")
            #expect(rows.first(where: { $0.durationSeconds == 1200 })?.friendInfoText == "Alex, Ben")
            #expect(rows.first(where: { $0.durationSeconds == 1500 })?.friendInfoText == expectedThreeFriendsText)
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
    func statsStore_navigationSkipsEmptyMonths() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))

            var calendar = Calendar.current

            func monthStart(_ year: Int, _ month: Int) -> Date {
                let components = DateComponents(year: year, month: month, day: 1, hour: 12)
                let date = calendar.date(from: components) ?? .distantPast
                return calendar.dateInterval(of: .month, for: date)?.start ?? date
            }

            func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
                let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
                return calendar.date(from: components) ?? .distantPast
            }

            _ = try dependencies.sessionRepository.create(
                startAt: date(2025, 1, 10, 10, 0),
                endAt: date(2025, 1, 10, 10, 30),
                platform: .pc,
                gameID: nil,
                durationSeconds: nil,
                note: nil,
                friendIDs: []
            )

            _ = try dependencies.sessionRepository.create(
                startAt: date(2025, 3, 10, 10, 0),
                endAt: date(2025, 3, 10, 11, 0),
                platform: .pc,
                gameID: nil,
                durationSeconds: nil,
                note: nil,
                friendIDs: []
            )

            let januaryStart = monthStart(2025, 1)
            let marchStart = monthStart(2025, 3)
            let store = StatsStore(dependencies: dependencies)

            store.send(.onAppear)
            #expect(store.state.availableMonthStarts == [januaryStart, marchStart])
            #expect(store.state.monthStart == marchStart)
            #expect(store.state.canGoPreviousMonth)
            #expect(!store.state.canGoNextMonth)

            store.send(.previousMonth)
            #expect(store.state.monthStart == januaryStart)
            #expect(!store.state.canGoPreviousMonth)
            #expect(store.state.canGoNextMonth)

            store.send(.nextMonth)
            #expect(store.state.monthStart == marchStart)
            #expect(store.state.canGoPreviousMonth)
            #expect(!store.state.canGoNextMonth)
        }
    }

    @Test
    func statsStore_noEndedRecordsDisablesNavigation() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))
            let store = StatsStore(dependencies: dependencies)

            let currentMonthStart = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()

            store.send(.onAppear)
            #expect(store.state.availableMonthStarts.isEmpty)
            #expect(store.state.monthStart == currentMonthStart)
            #expect(!store.state.canGoPreviousMonth)
            #expect(!store.state.canGoNextMonth)
            #expect(store.state.report != nil)
            #expect(store.state.report?.totalDurationSeconds == 0)
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
