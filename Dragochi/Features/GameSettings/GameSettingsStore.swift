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
        var enabledRemoteIDs: Set<String> = []
        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case onAppear
        case updateQuery(String)
        case clearQuery
        case toggle(remoteID: String)
        case closeTapped
    }

    @Published private(set) var state = State()

    private let gameRepository: GameRepository
    private let enabledSelectionRepository: EnabledGameSelectionRepository
    private let gameCatalogSyncService: GameCatalogSyncService
    private let isUITesting: Bool
    private let onClose: () -> Void

    init(dependencies: AppDependencies, onClose: @escaping () -> Void) {
        self.gameRepository = dependencies.gameRepository
        self.enabledSelectionRepository = dependencies.enabledGameSelectionRepository
        self.gameCatalogSyncService = dependencies.gameCatalogSyncService
        self.isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
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
        case .closeTapped:
            onClose()
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
            state.catalog = sortCatalog(fallbackCatalog)
            state.enabledRemoteIDs = try enabledSelectionRepository.fetchEnabledRemoteIDs()
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
            state.catalog = sortCatalog(catalog)
            state.enabledRemoteIDs = try enabledSelectionRepository.fetchEnabledRemoteIDs()
            state.errorMessage = nil
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func toggle(remoteID: String) {
        do {
            if state.enabledRemoteIDs.contains(remoteID) {
                try enabledSelectionRepository.disable(remoteID: remoteID)
                state.enabledRemoteIDs.remove(remoteID)
                try deleteUnreferencedGame(remoteID: remoteID)
            } else {
                try enabledSelectionRepository.enable(remoteID: remoteID)
                state.enabledRemoteIDs.insert(remoteID)
                try upsertEnabledGame(remoteID: remoteID)
            }
            state.errorMessage = nil
        } catch {
            state.errorMessage = error.localizedDescription
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
