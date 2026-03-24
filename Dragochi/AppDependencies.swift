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
    let gameArrangeManager: GameArrangeManager
    let friendListArrangeManager: FriendListArrangeManager
    let analyticsService: AnalyticsService
    let backupService: BackupService
    let gameCatalogService: GameCatalogService
    let gameCatalogSyncService: GameCatalogSyncService
    let auditLogger: AuditLogging

    init(modelContext: ModelContext, auditLogger: AuditLogging? = nil) {
        self.sessionRepository = SwiftDataSessionRepository(modelContext: modelContext)
        self.gameRepository = SwiftDataGameRepository(modelContext: modelContext)
        self.enabledGameSelectionRepository = SwiftDataEnabledGameSelectionRepository(modelContext: modelContext)
        self.friendRepository = SwiftDataFriendRepository(modelContext: modelContext)
        self.auditLogger = auditLogger ?? FileAuditLogger(fileURL: Self.makeAuditLogFileURL())
        self.gameArrangeManager = GameArrangeManager(sessionRepository: sessionRepository)
        self.friendListArrangeManager = FriendListArrangeManager(
            sessionRepository: sessionRepository,
            friendRepository: friendRepository
        )
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

    private static func makeAuditLogFileURL(fileManager: FileManager = .default) -> URL {
        let processInfo = ProcessInfo.processInfo
        let isRunningTests = processInfo.environment["XCTestConfigurationFilePath"] != nil
        let isUITesting = processInfo.arguments.contains("-ui-testing")

        if isRunningTests || isUITesting {
            return fileManager.temporaryDirectory
                .appendingPathComponent("dragochi-audit", isDirectory: true)
                .appendingPathComponent("audit-log-\(UUID().uuidString).jsonl")
        }

        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseDirectory
            .appendingPathComponent("Dragochi", isDirectory: true)
            .appendingPathComponent("Audit", isDirectory: true)
            .appendingPathComponent("audit-log.jsonl")
    }
}
