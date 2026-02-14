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
    let friendRepository: FriendRepository
    let analyticsService: AnalyticsService
    let backupService: BackupService

    init(modelContext: ModelContext) {
        self.sessionRepository = SwiftDataSessionRepository(modelContext: modelContext)
        self.gameRepository = SwiftDataGameRepository(modelContext: modelContext)
        self.friendRepository = SwiftDataFriendRepository(modelContext: modelContext)
        self.analyticsService = SwiftDataAnalyticsService(sessionRepository: sessionRepository)
        self.backupService = StubBackupService(
            sessionRepository: sessionRepository,
            gameRepository: gameRepository,
            friendRepository: friendRepository
        )
    }
}
