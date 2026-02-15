//
//  GameCatalogService.swift
//  Dragochi
//
//  Created by Codex on 15/2/2026.
//

import Foundation

struct CatalogGame: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let imageAssetName: String?
}

@MainActor
protocol GameCatalogService {
    func fallbackCatalog() -> [CatalogGame]
    func fetchLatestCatalog() async throws -> [CatalogGame]
}
