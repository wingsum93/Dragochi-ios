//
//  AppDIContainerTests.swift
//  DragochiTests
//
//  Created by Codex on 23/6/2026.
//

import Foundation
import Testing
@testable import Dragochi

@MainActor
struct AppDIContainerTests {
    @Test
    func databaseBackedDependencies_areSharedLazyInstances() throws {
        let container = try SwiftDataStack.makeInMemoryContainer()
        let dependencies = AppDIContainer(modelContainer: container)

        let sessionRepository = dependencies.sessionRepository
        let gameRepository = dependencies.gameRepository
        let enabledGameSelectionRepository = dependencies.enabledGameSelectionRepository
        let friendRepository = dependencies.friendRepository
        let gameCatalogSyncService = dependencies.gameCatalogSyncService

        #expect(isSameInstance(sessionRepository, dependencies.sessionRepository))
        #expect(isSameInstance(gameRepository, dependencies.gameRepository))
        #expect(isSameInstance(enabledGameSelectionRepository, dependencies.enabledGameSelectionRepository))
        #expect(isSameInstance(friendRepository, dependencies.friendRepository))
        #expect(gameCatalogSyncService === dependencies.gameCatalogSyncService)
    }

    @Test
    func viewModelFactories_createNewInstancesThatShareDependencies() throws {
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

        #expect(dependencies.makeMainViewModel() !== dependencies.makeMainViewModel())
        #expect(dependencies.makeHistoryViewModel() !== dependencies.makeHistoryViewModel())
        #expect(dependencies.makeStatisticViewModel() !== dependencies.makeStatisticViewModel())
        #expect(dependencies.makeSettingViewModel() !== dependencies.makeSettingViewModel())
        #expect(
            dependencies.makeAddSessionViewModel(draft: draft)
                !== dependencies.makeAddSessionViewModel(draft: draft)
        )
        #expect(
            dependencies.makeGameSettingViewModel(onClose: {})
                !== dependencies.makeGameSettingViewModel(onClose: {})
        )
        #expect(dependencies.makeFriendSettingViewModel() !== dependencies.makeFriendSettingViewModel())
        #expect(
            dependencies.makeAppleFriendImportViewModel()
                !== dependencies.makeAppleFriendImportViewModel()
        )

        let friend = try dependencies.friendRepository.create(
            name: "Shared Friend",
            handle: nil,
            avatarAssetName: FriendAvatarOptions.defaultAssetName,
            isActive: true
        )
        let firstFriendViewModel = dependencies.makeFriendSettingViewModel()
        let secondFriendViewModel = dependencies.makeFriendSettingViewModel()

        firstFriendViewModel.send(.onAppear)
        secondFriendViewModel.send(.onAppear)

        #expect(firstFriendViewModel.state.friends.map(\.id).contains(friend.id))
        #expect(secondFriendViewModel.state.friends.map(\.id).contains(friend.id))
    }

    private func isSameInstance(_ lhs: Any, _ rhs: Any) -> Bool {
        (lhs as AnyObject) === (rhs as AnyObject)
    }
}
