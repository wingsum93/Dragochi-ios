//
//  MVIViewModelsTests.swift
//  DragochiTests
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Dragochi

struct MVIViewModelsTests {
    @Test
    func mainStore_loadsLatestEndedSessionForResumeCard() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)

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

            let viewModel = dependencies.makeMainViewModel()
            viewModel.send(.onAppear)

            #expect(older.id != newer.id)
            #expect(viewModel.state.latestEndedSession?.id == newer.id)
        }
    }

    @Test
    func mainStore_noEndedSessionsKeepsLatestEndedSessionNil() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            let viewModel = dependencies.makeMainViewModel()

            viewModel.send(.onAppear)

            #expect(viewModel.state.latestEndedSession == nil)
            #expect(viewModel.state.friends.isEmpty)
        }
    }

    @Test
    func mainStore_trackingPauseResumeAndRestoreFlow() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)

            var current = Date(timeIntervalSince1970: 1_700_000_000)
            let viewModel = dependencies.makeMainViewModel(now: { current })

            viewModel.send(.onAppear)
            let gameAssets = Set(viewModel.state.games.compactMap(\.imageAssetName))
            #expect(gameAssets.isSuperset(of: ["apex", "lol", "wwz", "clash_royale", "volarant"]))

            viewModel.send(.startTapped(resumeLastSetupEnabled: false))
            #expect(viewModel.state.pendingAddSessionDraft?.mode == .preStartSetup)

            guard let selectedGameID = viewModel.state.games.first?.id else {
                Issue.record("Expected at least one game to be available.")
                return
            }

            let setup = SessionSetupInput(
                selectedGameID: selectedGameID,
                selectedPlatform: .pc,
                selectedFriendIDs: [],
                note: "focus run"
            )
            viewModel.send(.preStartSetupConfirmed(setup))
            #expect(viewModel.state.trackingStatus == .running)

            current = current.addingTimeInterval(15)
            viewModel.send(.tick)
            #expect(viewModel.state.elapsedSeconds == 15)

            viewModel.send(.pauseResumeTapped)
            #expect(viewModel.state.trackingStatus == .paused)
            #expect(viewModel.state.elapsedSeconds == 15)
            let snapshotData = viewModel.state.trackingSnapshotData
            #expect(snapshotData != nil)

            current = current.addingTimeInterval(20)
            viewModel.send(.tick)
            #expect(viewModel.state.elapsedSeconds == 15)

            let restoredStore = dependencies.makeMainViewModel(now: { current })
            restoredStore.send(.onAppear)
            restoredStore.send(.restoreTrackingSnapshot(snapshotData))
            #expect(restoredStore.state.trackingStatus == .paused)
            #expect(restoredStore.state.currentSessionID == viewModel.state.currentSessionID)

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
            let dependencies = AppDIContainer(modelContainer: container)
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
            let viewModel = dependencies.makeAddSessionViewModel(draft: draft,
                onClose: { didClose = true }
            )

            viewModel.send(.onAppear)
            viewModel.send(.saveTapped)

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
            let dependencies = AppDIContainer(modelContainer: container)
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

            let viewModel = dependencies.makeMainViewModel(now: { current })
            viewModel.send(.onAppear)
            viewModel.send(.startTapped(resumeLastSetupEnabled: true))

            #expect(viewModel.state.trackingStatus == .running)
            #expect(viewModel.state.pendingAddSessionDraft == nil)
            #expect(viewModel.state.activeSetup?.selectedGameID == game.id)
            #expect(viewModel.state.activeSetup?.selectedPlatform == .console)
            #expect(viewModel.state.activeSetup?.selectedFriendIDs == [activeFriend.id])
            #expect(viewModel.state.activeSetup?.note == "")

            guard let currentSessionID = viewModel.state.currentSessionID else {
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
            let dependencies = AppDIContainer(modelContainer: container)
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

            let viewModel = dependencies.makeMainViewModel(now: { current })
            viewModel.send(.onAppear)
            viewModel.send(.startTapped(resumeLastSetupEnabled: true))

            #expect(viewModel.state.trackingStatus == .idle)
            #expect(viewModel.state.currentSessionID == nil)
            #expect(viewModel.state.pendingAddSessionDraft?.mode == .preStartSetup)
        }
    }

    @Test
    func addSessionStore_preStartAllowsZeroPeople() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
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

            let viewModel = dependencies.makeAddSessionViewModel(draft: draft,
                onSetupConfirmed: { setup in receivedSetup = setup },
                onClose: { didClose = true }
            )

            viewModel.send(.onAppear)
            viewModel.send(.saveTapped)

            #expect(receivedSetup != nil)
            #expect(receivedSetup?.selectedFriendIDs.isEmpty == true)
            #expect(didClose)
        }
    }

    @Test
    func addSessionStore_showsNoTeammateChipsWhenNoActiveFriends() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
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

            let viewModel = dependencies.makeAddSessionViewModel(draft: draft)
            viewModel.send(.onAppear)

            #expect(viewModel.state.teammateChips.isEmpty)
        }
    }

    @Test
    func addSessionStore_usesPersistedFriendAvatarAsset() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
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

            let viewModel = dependencies.makeAddSessionViewModel(draft: draft)
            viewModel.send(.onAppear)

            #expect(viewModel.state.teammateChips.count == 1)
            #expect(viewModel.state.teammateChips.first?.avatarAssetName == "F2")
            #expect(viewModel.state.selectedFriendIDs.contains(friend.id))
        }
    }

    @Test
    func addSessionStore_ordersTeammateChipsByHistoricalPlaytime() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            let alex = try dependencies.friendRepository.create(
                name: "Alex",
                handle: nil,
                avatarAssetName: nil,
                isActive: true
            )
            let baby = try dependencies.friendRepository.create(
                name: "Baby",
                handle: nil,
                avatarAssetName: nil,
                isActive: true
            )

            _ = try dependencies.sessionRepository.create(
                startAt: Date(timeIntervalSince1970: 1_700_000_000),
                endAt: Date(timeIntervalSince1970: 1_700_003_600),
                platform: .pc,
                gameID: nil,
                durationSeconds: nil,
                note: nil,
                friendIDs: [baby.id]
            )
            _ = try dependencies.sessionRepository.create(
                startAt: Date(timeIntervalSince1970: 1_700_004_000),
                endAt: Date(timeIntervalSince1970: 1_700_004_600),
                platform: .pc,
                gameID: nil,
                durationSeconds: nil,
                note: nil,
                friendIDs: [alex.id]
            )

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
            let viewModel = dependencies.makeAddSessionViewModel(draft: draft)

            viewModel.send(.onAppear)

            #expect(viewModel.state.teammateChips.map(\.name) == ["Baby", "Alex"])
        }
    }

    @Test
    func friendSettingsStore_addEditDeleteAndValidation() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            let existing = try dependencies.friendRepository.create(
                name: "Mason",
                handle: nil,
                avatarAssetName: "M1",
                isActive: true,
                note: "Original note"
            )
            let viewModel = dependencies.makeFriendSettingViewModel()

            viewModel.send(.onAppear)
            #expect(viewModel.state.friends.count == 1)

            viewModel.send(.addTapped)
            viewModel.send(.updateEditingName("  mason  "))
            viewModel.send(.saveEditingTapped)
            #expect(viewModel.state.editValidationMessage != nil || viewModel.state.editValidationMessageKey != nil)

            viewModel.send(.updateEditingName("Ava"))
            viewModel.send(.selectEditingAvatar("F4"))
            viewModel.send(.updateEditingNote("Ava note"))
            viewModel.send(.saveEditingTapped)
            #expect(viewModel.state.friends.count == 2)

            guard let addedFriend = viewModel.state.friends.first(where: { $0.name == "Ava" }) else {
                Issue.record("Expected newly added friend.")
                return
            }
            #expect(addedFriend.avatarAssetName == "F4")
            #expect(addedFriend.isActive)
            #expect(addedFriend.order == 1)
            #expect(addedFriend.note == "Ava note")

            viewModel.send(.editTapped(existing.id))
            #expect(viewModel.state.editingNote == "Original note")
            viewModel.send(.updateEditingName("Mason Prime"))
            viewModel.send(.selectEditingAvatar("M2"))
            viewModel.send(.updateEditingNote("Updated note"))
            viewModel.send(.saveEditingTapped)
            #expect(viewModel.state.friends.first(where: { $0.id == existing.id })?.name == "Mason Prime")
            #expect(viewModel.state.friends.first(where: { $0.id == existing.id })?.avatarAssetName == "M2")
            #expect(viewModel.state.friends.first(where: { $0.id == existing.id })?.order == 0)
            #expect(viewModel.state.friends.first(where: { $0.id == existing.id })?.note == "Updated note")

            viewModel.send(.editTapped(existing.id))
            #expect(viewModel.state.editingNote == "Updated note")
            viewModel.send(.cancelEditingTapped)

            viewModel.send(.deleteTapped(existing.id))
            #expect(viewModel.state.isShowingDeleteDialog)
            viewModel.send(.confirmDeleteTapped)
            #expect(!viewModel.state.friends.contains(where: { $0.id == existing.id }))

            let persisted = try dependencies.friendRepository.fetch(id: existing.id)
            #expect(persisted?.isActive == false)
        }
    }

    @Test
    func friendSettingsStore_normalizesNonContiguousOrdersOnAppear() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            _ = try dependencies.friendRepository.create(
                name: "Cara",
                handle: nil,
                avatarAssetName: nil,
                isActive: true,
                order: 10,
                note: nil
            )
            _ = try dependencies.friendRepository.create(
                name: "Alex",
                handle: nil,
                avatarAssetName: nil,
                isActive: true,
                order: 10,
                note: nil
            )
            _ = try dependencies.friendRepository.create(
                name: "Ben",
                handle: nil,
                avatarAssetName: nil,
                isActive: true,
                order: 2,
                note: nil
            )
            let viewModel = dependencies.makeFriendSettingViewModel()

            viewModel.send(.onAppear)

            #expect(viewModel.state.friends.map(\.name) == ["Ben", "Alex", "Cara"])
            #expect(viewModel.state.friends.map(\.order) == [0, 1, 2])

            let persisted = try dependencies.friendRepository.fetchActive().sorted {
                if $0.order != $1.order { return $0.order < $1.order }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            #expect(persisted.map(\.order) == [0, 1, 2])
        }
    }

    @Test
    func friendSettingsStore_moveFriendsPersistsContiguousOrder() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            _ = try dependencies.friendRepository.create(
                name: "Alex",
                handle: nil,
                avatarAssetName: nil,
                isActive: true,
                order: 0,
                note: nil
            )
            _ = try dependencies.friendRepository.create(
                name: "Ben",
                handle: nil,
                avatarAssetName: nil,
                isActive: true,
                order: 1,
                note: nil
            )
            _ = try dependencies.friendRepository.create(
                name: "Cara",
                handle: nil,
                avatarAssetName: nil,
                isActive: true,
                order: 2,
                note: nil
            )
            let viewModel = dependencies.makeFriendSettingViewModel()

            viewModel.send(.onAppear)
            viewModel.send(.toggleReorderMode)
            viewModel.send(.moveFriends(IndexSet(integer: 0), 3))

            #expect(viewModel.state.friends.map(\.name) == ["Ben", "Cara", "Alex"])
            #expect(viewModel.state.friends.map(\.order) == [0, 1, 2])

            let persisted = try dependencies.friendRepository.fetchActive().sorted {
                if $0.order != $1.order { return $0.order < $1.order }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            #expect(persisted.map(\.name) == ["Ben", "Cara", "Alex"])
            #expect(persisted.map(\.order) == [0, 1, 2])
        }
    }

    @Test
    func friendSettingsStore_newFriendAppendsToEndAfterCustomOrder() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            _ = try dependencies.friendRepository.create(
                name: "Alex",
                handle: nil,
                avatarAssetName: nil,
                isActive: true,
                order: 0,
                note: nil
            )
            _ = try dependencies.friendRepository.create(
                name: "Ben",
                handle: nil,
                avatarAssetName: nil,
                isActive: true,
                order: 1,
                note: nil
            )
            let viewModel = dependencies.makeFriendSettingViewModel()

            viewModel.send(.onAppear)
            viewModel.send(.toggleReorderMode)
            viewModel.send(.moveFriends(IndexSet(integer: 0), 2))
            viewModel.send(.toggleReorderMode)

            viewModel.send(.addTapped)
            viewModel.send(.updateEditingName("Cara"))
            viewModel.send(.saveEditingTapped)

            #expect(viewModel.state.friends.map(\.name) == ["Ben", "Alex", "Cara"])
            #expect(viewModel.state.friends.map(\.order) == [0, 1, 2])
        }
    }

    @Test
    func appleFriendImportStore_selectingContactsStoresUniqueSelection() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            let viewModel = dependencies.makeAppleFriendImportViewModel()

            viewModel.send(
                .contactsSelected([
                    ImportedAppleContact(id: "C1", fullName: "Ava", email: "ava@example.com", phone: "111"),
                    ImportedAppleContact(id: "C1", fullName: "Ava Duplicate", email: nil, phone: nil),
                    ImportedAppleContact(id: "C2", fullName: "Ben", email: "ben@example.com", phone: "222")
                ])
            )

            #expect(viewModel.state.selectedContacts.count == 2)
            #expect(viewModel.state.selectedContacts.map(\.id) == ["C1", "C2"])
        }
    }

    @Test
    func appleFriendImportStore_confirmWithoutDuplicatesImportsAndAppendsOrder() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            _ = try dependencies.friendRepository.create(
                name: "Existing",
                handle: nil,
                avatarAssetName: nil,
                isActive: true,
                order: 0,
                note: nil
            )
            var didClose = false
            let viewModel = dependencies.makeAppleFriendImportViewModel(
                onClose: { didClose = true }
            )

            viewModel.send(
                .contactsSelected([
                    ImportedAppleContact(id: "C1", fullName: "Ben", email: "ben@example.com", phone: "111"),
                    ImportedAppleContact(id: "C2", fullName: "Cara", email: nil, phone: "222")
                ])
            )
            viewModel.send(.confirmImportTapped)

            #expect(didClose)
            let persisted = try dependencies.friendRepository.fetchActive().sorted { $0.order < $1.order }
            #expect(persisted.map(\.name) == ["Existing", "Ben", "Cara"])
            #expect(persisted.map(\.order) == [0, 1, 2])
        }
    }

    @Test
    func appleFriendImportStore_duplicateNameShowsConfirmThenImportsWhenConfirmed() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            _ = try dependencies.friendRepository.create(
                name: "Ava",
                handle: nil,
                avatarAssetName: nil,
                isActive: true,
                order: 0,
                note: nil
            )
            var didClose = false
            let viewModel = dependencies.makeAppleFriendImportViewModel(
                onClose: { didClose = true }
            )

            viewModel.send(
                .contactsSelected([
                    ImportedAppleContact(id: "C1", fullName: "Ava", email: "ava@example.com", phone: nil),
                    ImportedAppleContact(id: "C2", fullName: "Ben", email: nil, phone: nil)
                ])
            )
            viewModel.send(.confirmImportTapped)

            #expect(viewModel.state.isShowingDuplicateAlert)
            #expect(viewModel.state.duplicateCount == 1)
            #expect(!didClose)

            viewModel.send(.confirmDuplicateImportTapped)
            #expect(didClose)

            let persisted = try dependencies.friendRepository.fetchActive()
            #expect(persisted.count == 3)
            #expect(persisted.filter { $0.name == "Ava" }.count == 2)
            #expect(persisted.contains(where: { $0.name == "Ben" }))
        }
    }

    @Test
    func appleFriendImportStore_persistsNameOnlyForImportedContacts() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            var didClose = false
            let viewModel = dependencies.makeAppleFriendImportViewModel(
                onClose: { didClose = true }
            )

            viewModel.send(
                .contactsSelected([
                    ImportedAppleContact(id: "C1", fullName: "Luna", email: "luna@example.com", phone: "333")
                ])
            )
            viewModel.send(.confirmImportTapped)

            #expect(didClose)
            guard let persisted = try dependencies.friendRepository.fetchActive().first(where: { $0.name == "Luna" }) else {
                Issue.record("Expected imported friend named Luna.")
                return
            }

            #expect(persisted.handle == nil)
            #expect(persisted.avatarAssetName == nil)
            #expect(persisted.note == nil)
            #expect(persisted.isActive)
        }
    }

    @Test
    func gameSettingsStore_doneTappedWithoutChangesClosesImmediately() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            var didClose = false
            let viewModel = dependencies.makeGameSettingViewModel(
                onClose: { didClose = true },
                isUITesting: true
            )

            viewModel.send(.onAppear)
            viewModel.send(.doneTapped)

            #expect(didClose)
            #expect(!viewModel.state.isShowingConfirmChangesDialog)
        }
    }

    @Test
    func gameSettingsStore_doneTappedWithChangesShowsDialogAndNoKeepsPage() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            var didClose = false
            let viewModel = dependencies.makeGameSettingViewModel(
                onClose: { didClose = true },
                isUITesting: true
            )

            viewModel.send(.onAppear)
            guard let remoteID = viewModel.state.catalog.first?.id else {
                Issue.record("Expected catalog to contain at least one game.")
                return
            }

            let persistedBeforeToggle = try dependencies.enabledGameSelectionRepository.fetchEnabledRemoteIDs()

            viewModel.send(.toggle(remoteID: remoteID))

            let persistedAfterToggle = try dependencies.enabledGameSelectionRepository.fetchEnabledRemoteIDs()
            #expect(persistedAfterToggle == persistedBeforeToggle)
            #expect(viewModel.state.draftEnabledRemoteIDs != viewModel.state.originalEnabledRemoteIDs)

            viewModel.send(.doneTapped)
            #expect(viewModel.state.isShowingConfirmChangesDialog)
            #expect(!didClose)

            viewModel.send(.cancelSaveChanges)

            let persistedAfterCancel = try dependencies.enabledGameSelectionRepository.fetchEnabledRemoteIDs()
            #expect(!viewModel.state.isShowingConfirmChangesDialog)
            #expect(persistedAfterCancel == persistedBeforeToggle)
            #expect(!didClose)
        }
    }

    @Test
    func gameSettingsStore_confirmSavePersistsDiffAndCloses() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            var didClose = false
            let viewModel = dependencies.makeGameSettingViewModel(
                onClose: { didClose = true },
                isUITesting: true
            )

            viewModel.send(.onAppear)
            guard let remoteID = viewModel.state.catalog.first?.id else {
                Issue.record("Expected catalog to contain at least one game.")
                return
            }

            #expect(try dependencies.gameRepository.fetch(remoteID: remoteID) != nil)

            viewModel.send(.toggle(remoteID: remoteID))
            viewModel.send(.doneTapped)
            #expect(viewModel.state.isShowingConfirmChangesDialog)

            viewModel.send(.confirmSaveChanges)

            let persistedAfterConfirm = try dependencies.enabledGameSelectionRepository.fetchEnabledRemoteIDs()
            #expect(didClose)
            #expect(!viewModel.state.isShowingConfirmChangesDialog)
            #expect(viewModel.state.originalEnabledRemoteIDs == viewModel.state.draftEnabledRemoteIDs)
            #expect(!persistedAfterConfirm.contains(remoteID))
            #expect(try dependencies.gameRepository.fetch(remoteID: remoteID) == nil)
        }
    }

    @Test
    func gameSettingsStore_backTappedClosesWithoutSavingDraftChanges() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            var didClose = false
            let viewModel = dependencies.makeGameSettingViewModel(
                onClose: { didClose = true },
                isUITesting: true
            )

            viewModel.send(.onAppear)
            guard let remoteID = viewModel.state.catalog.first?.id else {
                Issue.record("Expected catalog to contain at least one game.")
                return
            }

            let persistedBeforeBack = try dependencies.enabledGameSelectionRepository.fetchEnabledRemoteIDs()
            viewModel.send(.toggle(remoteID: remoteID))
            viewModel.send(.backTapped)
            let persistedAfterBack = try dependencies.enabledGameSelectionRepository.fetchEnabledRemoteIDs()

            #expect(didClose)
            #expect(persistedAfterBack == persistedBeforeBack)
        }
    }

    @Test
    func historyStore_buildsSections() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)

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

            let viewModel = dependencies.makeHistoryViewModel()
            viewModel.send(.onAppear)
            #expect(!viewModel.state.sections.isEmpty)
            #expect(viewModel.state.totalPlaytimeSeconds > 0)

            let rows = viewModel.state.sections.flatMap(\.rows)
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
            let dependencies = AppDIContainer(modelContainer: container)
            let viewModel = dependencies.makeStatisticViewModel()

            viewModel.send(.onAppear)
            #expect(viewModel.state.report != nil)
        }
    }

    @Test
    func statsStore_navigationSkipsEmptyMonths() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)

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
            let viewModel = dependencies.makeStatisticViewModel()

            viewModel.send(.onAppear)
            #expect(viewModel.state.availableMonthStarts == [januaryStart, marchStart])
            #expect(viewModel.state.monthStart == marchStart)
            #expect(viewModel.state.canGoPreviousMonth)
            #expect(!viewModel.state.canGoNextMonth)

            viewModel.send(.previousMonth)
            #expect(viewModel.state.monthStart == januaryStart)
            #expect(!viewModel.state.canGoPreviousMonth)
            #expect(viewModel.state.canGoNextMonth)

            viewModel.send(.nextMonth)
            #expect(viewModel.state.monthStart == marchStart)
            #expect(viewModel.state.canGoPreviousMonth)
            #expect(!viewModel.state.canGoNextMonth)
        }
    }

    @Test
    func statsStore_noEndedRecordsDisablesNavigation() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            let viewModel = dependencies.makeStatisticViewModel()

            let currentMonthStart = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()

            viewModel.send(.onAppear)
            #expect(viewModel.state.availableMonthStarts.isEmpty)
            #expect(viewModel.state.monthStart == currentMonthStart)
            #expect(!viewModel.state.canGoPreviousMonth)
            #expect(!viewModel.state.canGoNextMonth)
            #expect(viewModel.state.report != nil)
            #expect(viewModel.state.report?.totalDurationSeconds == 0)
        }
    }

    @Test
    func settingsStore_toggleAndBackup() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            let viewModel = dependencies.makeSettingViewModel()

            viewModel.send(.toggleICloud(true))
            #expect(viewModel.state.isICloudSyncOn)

            viewModel.send(.exportTapped)
            #expect(viewModel.state.lastBackupDate != nil)
        }
    }

    @Test
    func settingsStore_reportIssueCreatesDraftWithAttachmentAndTemplateBody() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            let viewModel = dependencies.makeSettingViewModel()

            viewModel.send(.reportIssueTapped(canSendMail: true))

            guard let draft = viewModel.state.issueReportDraft else {
                Issue.record("Expected issue report draft when Mail is available.")
                return
            }

            #expect(draft.recipient == "wingsum.developer@gmail.com")
            #expect(draft.subject == "Dragochi Issue Report")
            #expect(draft.body.contains("Issue Summary:"))
            #expect(draft.body.contains("--- Environment ---"))
            #expect(draft.body.contains("App Version:"))
            #expect(draft.body.contains("OS:"))
            #expect(draft.body.contains("Device:"))
            #expect(draft.body.contains("Timestamp:"))

            guard let attachmentURL = draft.attachmentURL else {
                Issue.record("Expected non-nil audit attachment URL in issue draft.")
                return
            }
            #expect(FileManager.default.fileExists(atPath: attachmentURL.path))
        }
    }

    @Test
    func settingsStore_reportIssueWhenMailUnavailableShowsFallbackAlert() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDIContainer(modelContainer: container)
            let viewModel = dependencies.makeSettingViewModel()

            viewModel.send(.reportIssueTapped(canSendMail: false))

            #expect(viewModel.state.issueReportDraft == nil)
            #expect(viewModel.state.isShowingMailUnavailableAlert)
        }
    }
}
