//
//  FirebaseRemoteConfigGameCatalogService.swift
//  Dragochi
//
//  Created by Codex on 15/2/2026.
//

import Foundation

import FirebaseRemoteConfig
import FirebaseCore

private let defaultFallbackCatalog: [CatalogGame] = [
    CatalogGame(id: "apex_legends", name: "Apex Legends", imageAssetName: "apex"),
    CatalogGame(id: "lol", name: "LOL", imageAssetName: "lol"),
    CatalogGame(id: "world_war_z", name: "World War Z", imageAssetName: "wwz"),
    CatalogGame(id: "clash_royale", name: "Clash Royale", imageAssetName: "clash_royale"),
    CatalogGame(id: "valorant", name: "Valorant", imageAssetName: "volarant"),
    CatalogGame(id: "fallback", name: "Fall Back", imageAssetName: "volarant")
]

@MainActor
final class FirebaseRemoteConfigGameCatalogService: GameCatalogService {
    private let catalogKey: String
    private let fallback: [CatalogGame]
    private let decoder = JSONDecoder()

    init(
        catalogKey: String = "game_catalog_json",
        fallback: [CatalogGame]? = nil
    ) {
        self.catalogKey = catalogKey
        self.fallback = fallback ?? defaultFallbackCatalog
    }

    func fallbackCatalog() -> [CatalogGame] {
        fallback
    }

    func fetchLatestCatalog() async throws -> [CatalogGame] {

        guard FirebaseApp.app() != nil else {
            print("FCB Game Catalog: Firebase not yet initialized. Using fallback.")
            return fallback
        }
        
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings

        if let fallbackJSONString = fallbackJSONString() {
            remoteConfig.setDefaults([catalogKey: fallbackJSONString as NSObject])
        }

        try await fetchAndActivate(remoteConfig: remoteConfig)

        let raw = remoteConfig.configValue(forKey: catalogKey).stringValue
        if let decoded = decodeCatalog(from: raw) {
            return decoded
        }

        return fallback
    }

    private func fetchAndActivate(remoteConfig: RemoteConfig) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            remoteConfig.fetchAndActivate { _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }

    private func fallbackJSONString() -> String? {
        guard let data = try? JSONEncoder().encode(fallback) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func decodeCatalog(from json: String) -> [CatalogGame]? {
        guard let data = json.data(using: .utf8) else { return nil }
        guard let decoded = try? decoder.decode([CatalogGame].self, from: data) else { return nil }

        let cleaned = decoded.compactMap { item -> CatalogGame? in
            let id = item.id.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !id.isEmpty, !name.isEmpty else { return nil }
            return CatalogGame(id: id, name: name, imageAssetName: item.imageAssetName)
        }

        return cleaned.isEmpty ? nil : cleaned
    }
}
