//
//  AppDependencies.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import SwiftData

@MainActor
struct AppDependencies {
    let sessionRepository: SessionRepository
    let gameRepository: GameRepository
    let enabledGameSelectionRepository: EnabledGameSelectionRepository
    let friendRepository: FriendRepository
    let gameArranger: GameArranger
    let analyticsService: AnalyticsService
    let backupService: BackupService
    let gameCatalogService: GameCatalogService
    let gameCatalogSyncService: GameCatalogSyncService

    init(modelContext: ModelContext) {
        self.sessionRepository = SwiftDataSessionRepository(modelContext: modelContext)
        self.gameRepository = SwiftDataGameRepository(modelContext: modelContext)
        self.enabledGameSelectionRepository = SwiftDataEnabledGameSelectionRepository(modelContext: modelContext)
        self.friendRepository = SwiftDataFriendRepository(modelContext: modelContext)
        self.gameArranger = GameArranger(sessionRepository: sessionRepository)
        self.analyticsService = SwiftDataAnalyticsService(sessionRepository: sessionRepository)
        self.backupService = StubBackupService(
            sessionRepository: sessionRepository,
            gameRepository: gameRepository,
            friendRepository: friendRepository
        )
        self.gameCatalogService = FirebaseRemoteConfigGameCatalogService()
        let catalogDefaults = Self.makeCatalogDefaults()
        self.gameCatalogSyncService = GameCatalogSyncService(
            gameRepository: gameRepository,
            enabledSelectionRepository: enabledGameSelectionRepository,
            catalogService: gameCatalogService,
            defaults: catalogDefaults
        )
    }

    private static func makeCatalogDefaults() -> UserDefaults {
        let processInfo = ProcessInfo.processInfo
        let isRunningTests = processInfo.environment["XCTestConfigurationFilePath"] != nil
        let isUITesting = processInfo.arguments.contains("-ui-testing")
        if isRunningTests || isUITesting {
            return UserDefaults(suiteName: "dragochi.catalog.defaults.\(UUID().uuidString)") ?? .standard
        }
        return .standard
    }
}
