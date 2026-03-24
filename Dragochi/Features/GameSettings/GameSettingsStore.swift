//
//  GameSettingsStore.swift
//  Dragochi
//
//  Created by Codex on 15/2/2026.
//

import Foundation
import Combine

@MainActor
final class GameSettingsStore: ObservableObject {
    struct State: Equatable {
        var query: String = ""
        var catalog: [CatalogGame] = []
        var originalEnabledRemoteIDs: Set<String> = []
        var draftEnabledRemoteIDs: Set<String> = []
        var isShowingConfirmChangesDialog: Bool = false
        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case onAppear
        case updateQuery(String)
        case clearQuery
        case toggle(remoteID: String)
        case backTapped
        case doneTapped
        case confirmSaveChanges
        case cancelSaveChanges
    }

    @Published private(set) var state = State()

    private let gameRepository: GameRepository
    private let enabledSelectionRepository: EnabledGameSelectionRepository
    private let gameCatalogSyncService: GameCatalogSyncService
    private let auditLogger: AuditLogging
    private let isUITesting: Bool
    private let onClose: () -> Void

    init(
        dependencies: AppDependencies,
        onClose: @escaping () -> Void,
        isUITesting: Bool = ProcessInfo.processInfo.arguments.contains("-ui-testing")
    ) {
        self.gameRepository = dependencies.gameRepository
        self.enabledSelectionRepository = dependencies.enabledGameSelectionRepository
        self.gameCatalogSyncService = dependencies.gameCatalogSyncService
        self.auditLogger = dependencies.auditLogger
        self.isUITesting = isUITesting
        self.onClose = onClose
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            load()
        case .updateQuery(let query):
            state.query = query
        case .clearQuery:
            state.query = ""
        case .toggle(let remoteID):
            toggle(remoteID: remoteID)
        case .backTapped:
            onClose()
        case .doneTapped:
            doneTapped()
        case .confirmSaveChanges:
            confirmSaveChanges()
        case .cancelSaveChanges:
            state.isShowingConfirmChangesDialog = false
        }
    }

    var filteredCatalog: [CatalogGame] {
        let trimmed = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return state.catalog }
        return state.catalog.filter { game in
            game.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private func load() {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            let fallbackCatalog = try gameCatalogSyncService.seedFromFallbackIfNeeded()
            let sortedCatalog = sortCatalog(fallbackCatalog)
            state.catalog = sortedCatalog

            let fetchedEnabled = try enabledSelectionRepository.fetchEnabledRemoteIDs()
            let catalogIDs = Set(sortedCatalog.map(\.id))
            let enabledWithinCatalog = fetchedEnabled.intersection(catalogIDs)

            state.originalEnabledRemoteIDs = enabledWithinCatalog
            state.draftEnabledRemoteIDs = enabledWithinCatalog
            state.isShowingConfirmChangesDialog = false
            state.errorMessage = nil

            guard !isUITesting else { return }
            Task { [weak self] in
                await self?.refreshFromRemote()
            }
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func refreshFromRemote() async {
        do {
            let catalog = try await gameCatalogSyncService.refreshFromRemote()
            let sortedCatalog = sortCatalog(catalog)
            state.catalog = sortedCatalog

            let catalogIDs = Set(sortedCatalog.map(\.id))
            let hasUnsavedChanges = state.draftEnabledRemoteIDs != state.originalEnabledRemoteIDs

            if hasUnsavedChanges {
                state.originalEnabledRemoteIDs.formIntersection(catalogIDs)
                state.draftEnabledRemoteIDs.formIntersection(catalogIDs)
            } else {
                let fetchedEnabled = try enabledSelectionRepository.fetchEnabledRemoteIDs()
                let enabledWithinCatalog = fetchedEnabled.intersection(catalogIDs)
                state.originalEnabledRemoteIDs = enabledWithinCatalog
                state.draftEnabledRemoteIDs = enabledWithinCatalog
            }

            state.errorMessage = nil
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func toggle(remoteID: String) {
        if state.draftEnabledRemoteIDs.contains(remoteID) {
            state.draftEnabledRemoteIDs.remove(remoteID)
        } else {
            state.draftEnabledRemoteIDs.insert(remoteID)
        }
        state.errorMessage = nil
    }

    private func doneTapped() {
        guard state.draftEnabledRemoteIDs != state.originalEnabledRemoteIDs else {
            onClose()
            return
        }
        state.isShowingConfirmChangesDialog = true
    }

    private func confirmSaveChanges() {
        let toEnable = state.draftEnabledRemoteIDs.subtracting(state.originalEnabledRemoteIDs).sorted()
        let toDisable = state.originalEnabledRemoteIDs.subtracting(state.draftEnabledRemoteIDs).sorted()
        var enabledAppliedCount = 0
        var disabledAppliedCount = 0

        do {
            for remoteID in toEnable {
                try enabledSelectionRepository.enable(remoteID: remoteID)
                try upsertEnabledGame(remoteID: remoteID)
                enabledAppliedCount += 1
            }

            for remoteID in toDisable {
                try enabledSelectionRepository.disable(remoteID: remoteID)
                try deleteUnreferencedGame(remoteID: remoteID)
                disabledAppliedCount += 1
            }

            state.originalEnabledRemoteIDs = state.draftEnabledRemoteIDs
            state.isShowingConfirmChangesDialog = false
            state.errorMessage = nil
            auditLogger.log(
                action: .gameSettingsChangesSaved,
                outcome: .success,
                metadata: [
                    "enable_count": String(toEnable.count),
                    "disable_count": String(toDisable.count),
                    "enabled_applied_count": String(enabledAppliedCount),
                    "disabled_applied_count": String(disabledAppliedCount)
                ]
            )
            onClose()
        } catch {
            state.isShowingConfirmChangesDialog = false
            state.errorMessage = error.localizedDescription
            auditLogger.log(
                action: .gameSettingsChangesSaved,
                outcome: .failure,
                metadata: AuditMetadata.withError(
                    [
                        "enable_count": String(toEnable.count),
                        "disable_count": String(toDisable.count),
                        "enabled_applied_count": String(enabledAppliedCount),
                        "disabled_applied_count": String(disabledAppliedCount)
                    ],
                    error: error
                )
            )
        }
    }

    private func upsertEnabledGame(remoteID: String) throws {
        guard let catalogGame = state.catalog.first(where: { $0.id == remoteID }) else { return }

        if var existing = try gameRepository.fetch(remoteID: remoteID) {
            existing.name = catalogGame.name
            existing.imageAssetName = catalogGame.imageAssetName
            _ = try gameRepository.upsert(existing)
        } else {
            _ = try gameRepository.create(
                name: catalogGame.name,
                imageAssetName: catalogGame.imageAssetName,
                remoteID: remoteID
            )
        }
    }

    private func deleteUnreferencedGame(remoteID: String) throws {
        guard let game = try gameRepository.fetch(remoteID: remoteID) else { return }
        let referencedGameIDs = try gameRepository.referencedGameIDs()
        guard !referencedGameIDs.contains(game.id) else { return }
        try gameRepository.delete(id: game.id)
    }

    private func sortCatalog(_ catalog: [CatalogGame]) -> [CatalogGame] {
        catalog.sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}
