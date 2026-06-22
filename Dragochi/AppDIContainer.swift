//
//  AppDIContainer.swift
//  Dragochi
//
//  Created by eric ho on 29/5/2026.
//
import Foundation
import SwiftData

@MainActor
final class AppDIContainer {
    private let modelContext: ModelContext
    private let injectedAuditLogger: AuditLogging?

    private(set) lazy var sessionRepository: SessionRepository = SwiftDataSessionRepository(modelContext: modelContext)
    private(set) lazy var gameRepository: GameRepository = SwiftDataGameRepository(modelContext: modelContext)
    private(set) lazy var enabledGameSelectionRepository: EnabledGameSelectionRepository = SwiftDataEnabledGameSelectionRepository(
        modelContext: modelContext
    )
    private(set) lazy var friendRepository: FriendRepository = SwiftDataFriendRepository(modelContext: modelContext)

    private lazy var gameArrangeManager = GameArrangeManager(sessionRepository: sessionRepository)
    private lazy var friendListArrangeManager = FriendListArrangeManager(
        sessionRepository: sessionRepository,
        friendRepository: friendRepository
    )
    private lazy var analyticsService: AnalyticsService = SwiftDataAnalyticsService(sessionRepository: sessionRepository)
    private lazy var backupService: BackupService = StubBackupService(
        sessionRepository: sessionRepository,
        gameRepository: gameRepository,
        friendRepository: friendRepository
    )
    private lazy var gameCatalogService: GameCatalogService = FirebaseRemoteConfigGameCatalogService()
    private(set) lazy var gameCatalogSyncService = GameCatalogSyncService(
        gameRepository: gameRepository,
        enabledSelectionRepository: enabledGameSelectionRepository,
        catalogService: gameCatalogService,
        defaults: Self.makeCatalogDefaults()
    )
    private lazy var auditLogger: AuditLogging = injectedAuditLogger ?? FileAuditLogger(
        fileURL: Self.makeAuditLogFileURL()
    )

    init(modelContainer: ModelContainer, auditLogger: AuditLogging? = nil) {
        self.modelContext = ModelContext(modelContainer)
        self.injectedAuditLogger = auditLogger
    }

    func makeMainViewModel(now: @escaping () -> Date = Date.init) -> MainViewModel {
        MainViewModel(
            sessionRepository: sessionRepository,
            gameRepository: gameRepository,
            friendRepository: friendRepository,
            gameCatalogSyncService: gameCatalogSyncService,
            auditLogger: auditLogger,
            now: now
        )
    }

    func makeHistoryViewModel() -> HistoryViewModel {
        HistoryViewModel(
            sessionRepository: sessionRepository,
            gameRepository: gameRepository,
            friendRepository: friendRepository
        )
    }

    func makeStatisticViewModel() -> StatisticViewModel {
        StatisticViewModel(
            analyticsService: analyticsService,
            sessionRepository: sessionRepository,
            gameRepository: gameRepository
        )
    }

    func makeSettingViewModel() -> SettingViewModel {
        SettingViewModel(
            backupService: backupService,
            auditLogger: auditLogger
        )
    }

    func makeAddSessionViewModel(
        draft: AddSessionDraft,
        onSetupConfirmed: ((SessionSetupInput) -> Void)? = nil,
        onOpenGameSettings: @escaping () -> Void = {},
        onOpenFriendSettings: @escaping () -> Void = {},
        onClose: @escaping () -> Void = {}
    ) -> AddSessionViewModel {
        AddSessionViewModel(
            sessionRepository: sessionRepository,
            gameRepository: gameRepository,
            enabledGameSelectionRepository: enabledGameSelectionRepository,
            friendRepository: friendRepository,
            gameArrangeManager: gameArrangeManager,
            friendListArrangeManager: friendListArrangeManager,
            gameCatalogSyncService: gameCatalogSyncService,
            auditLogger: auditLogger,
            draft: draft,
            onSetupConfirmed: onSetupConfirmed,
            onOpenGameSettings: onOpenGameSettings,
            onOpenFriendSettings: onOpenFriendSettings,
            onClose: onClose
        )
    }

    func makeGameSettingViewModel(
        onClose: @escaping () -> Void,
        isUITesting: Bool = ProcessInfo.processInfo.arguments.contains("-ui-testing")
    ) -> GameSettingViewModel {
        GameSettingViewModel(
            gameRepository: gameRepository,
            enabledSelectionRepository: enabledGameSelectionRepository,
            gameCatalogSyncService: gameCatalogSyncService,
            auditLogger: auditLogger,
            onClose: onClose,
            isUITesting: isUITesting
        )
    }

    func makeFriendSettingViewModel(onClose: @escaping () -> Void = {}) -> FriendSettingViewModel {
        FriendSettingViewModel(
            friendRepository: friendRepository,
            auditLogger: auditLogger,
            onClose: onClose
        )
    }

    func makeAppleFriendImportViewModel(onClose: @escaping () -> Void = {}) -> AppleFriendImportViewModel {
        AppleFriendImportViewModel(
            friendRepository: friendRepository,
            auditLogger: auditLogger,
            onClose: onClose
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
