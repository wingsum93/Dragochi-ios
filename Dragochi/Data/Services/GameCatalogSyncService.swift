//
//  GameCatalogSyncService.swift
//  Dragochi
//
//  Created by Codex on 15/2/2026.
//

import Foundation

@MainActor
final class GameCatalogSyncService {
    private let gameRepository: GameRepository
    private let enabledSelectionRepository: EnabledGameSelectionRepository
    private let catalogService: GameCatalogService
    private let defaults: UserDefaults
    private let hasInitializedDefaultsKey = "gameCatalog.initialSelectionV1"

    init(
        gameRepository: GameRepository,
        enabledSelectionRepository: EnabledGameSelectionRepository,
        catalogService: GameCatalogService,
        defaults: UserDefaults = .standard
    ) {
        self.gameRepository = gameRepository
        self.enabledSelectionRepository = enabledSelectionRepository
        self.catalogService = catalogService
        self.defaults = defaults
    }

    func seedFromFallbackIfNeeded() throws -> [CatalogGame] {
        let catalog = catalogService.fallbackCatalog()
        try apply(catalog: catalog, persistDefaultSelectionIfNeeded: true)
        return catalog
    }

    func refreshFromRemote() async throws -> [CatalogGame] {
        let catalog = try await catalogService.fetchLatestCatalog()
        try apply(catalog: catalog, persistDefaultSelectionIfNeeded: false)
        return catalog
    }

    func currentEnabledGamesForAddSession() throws -> [GameEntity] {
        let enabledIDs = try enabledSelectionRepository.fetchEnabledRemoteIDs()
        guard !enabledIDs.isEmpty else { return [] }

        let allGames = try gameRepository.fetchAll()
        return allGames
            .filter { game in
                guard let remoteID = game.remoteID else { return false }
                return enabledIDs.contains(remoteID)
            }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    private func apply(catalog: [CatalogGame], persistDefaultSelectionIfNeeded: Bool) throws {
        let catalogIDs = Set(catalog.map(\.id))

        if persistDefaultSelectionIfNeeded && !defaults.bool(forKey: hasInitializedDefaultsKey) && !catalogIDs.isEmpty {
            for id in catalogIDs {
                try enabledSelectionRepository.enable(remoteID: id)
            }
            defaults.set(true, forKey: hasInitializedDefaultsKey)
        }

        try enabledSelectionRepository.removeMissing(remoteIDs: catalogIDs)

        let enabledIDs = try enabledSelectionRepository.fetchEnabledRemoteIDs()
        let existingGames = try gameRepository.fetchAll()
        var existingByRemoteID: [String: GameEntity] = [:]
        for game in existingGames {
            guard let remoteID = game.remoteID else { continue }
            existingByRemoteID[remoteID] = game
        }

        for game in catalog {
            if var existing = existingByRemoteID[game.id] {
                existing.name = game.name
                existing.imageAssetName = game.imageAssetName
                _ = try gameRepository.upsert(existing)
            } else if enabledIDs.contains(game.id) {
                _ = try gameRepository.create(
                    name: game.name,
                    imageAssetName: game.imageAssetName,
                    remoteID: game.id
                )
            }
        }

        let referencedGameIDs = try gameRepository.referencedGameIDs()
        let allGames = try gameRepository.fetchAll()

        for game in allGames {
            guard let remoteID = game.remoteID else { continue }

            let isEnabled = enabledIDs.contains(remoteID)
            let isReferenced = referencedGameIDs.contains(game.id)

            if !isEnabled && !isReferenced {
                try gameRepository.delete(id: game.id)
            }
        }
    }
}
