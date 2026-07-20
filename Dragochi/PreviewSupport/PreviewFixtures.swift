//
//  PreviewFixtures.swift
//  Dragochi
//
//  Created by Codex on 21/7/2026.
//

#if DEBUG
import Foundation

@MainActor
struct PreviewAuditLoggerFixture: AuditLogging {
    func log(action: AuditAction, outcome: AuditOutcome, metadata: [String: String]) {}
}

@MainActor
struct PreviewGameCatalogServiceFixture: GameCatalogService {
    let catalog: [CatalogGame]

    func fallbackCatalog() -> [CatalogGame] {
        catalog
    }

    func fetchLatestCatalog() async throws -> [CatalogGame] {
        catalog
    }
}

@MainActor
enum PreviewFixtures {
    static let valorantID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let apexID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let masonID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1")!
    static let avaID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaab1")!

    static var games: [GameEntity] {
        [
            GameEntity(id: valorantID, name: "Valorant", imageAssetName: "volarant", remoteID: "valorant"),
            GameEntity(id: apexID, name: "Apex Legends", imageAssetName: "apex", remoteID: "apex")
        ]
    }

    static var friends: [FriendEntity] {
        [
            FriendEntity(id: masonID, name: "Mason", avatarAssetName: "M1", order: 0),
            FriendEntity(id: avaID, name: "Ava", avatarAssetName: "F1", order: 1)
        ]
    }

    static func gameCatalogSyncService(
        gameRepository: GameRepository,
        enabledSelectionRepository: EnabledGameSelectionRepository
    ) -> GameCatalogSyncService {
        GameCatalogSyncService(
            gameRepository: gameRepository,
            enabledSelectionRepository: enabledSelectionRepository,
            catalogService: PreviewGameCatalogServiceFixture(
                catalog: games.map {
                    CatalogGame(id: $0.remoteID ?? $0.id.uuidString, name: $0.name, imageAssetName: $0.imageAssetName)
                }
            ),
            defaults: UserDefaults(suiteName: "PreviewFixtures.\(UUID().uuidString)") ?? .standard
        )
    }
}
#endif
