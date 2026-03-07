//
//  GameArrangerTests.swift
//  DragochiTests
//
//  Created by Codex on 8/3/2026.
//

import Foundation
import Testing
@testable import Dragochi

struct GameArrangerTests {
    @Test
    @MainActor
    func getWeightedGameList_returnsAlphabeticalOrderWhenNoSessions() throws {
        let games = makeGames()
        let arranger = GameArranger(sessionRepository: StubSessionRepository(endedSessions: []))

        let orderedGames = try arranger.getWeightedGameList(from: games)

        #expect(orderedGames.map(\.name) == ["Apex Legends", "LOL", "Valorant"])
    }

    @Test
    @MainActor
    func getWeightedGameList_placesSinglePlayedGameFirst() throws {
        let games = makeGames()
        let lol = games.first { $0.name == "LOL" }!
        let arranger = GameArranger(
            sessionRepository: StubSessionRepository(
                endedSessions: [
                    makeSession(
                        gameID: lol.id,
                        startAt: Date(timeIntervalSince1970: 1_700_000_000),
                        endAt: Date(timeIntervalSince1970: 1_700_000_600)
                    )
                ]
            )
        )

        let orderedGames = try arranger.getWeightedGameList(from: games)

        #expect(orderedGames.map(\.name) == ["LOL", "Apex Legends", "Valorant"])
    }

    @Test
    @MainActor
    func getWeightedGameList_placesMostRecentGameFirstThenUsesDurationAndCount() throws {
        let games = makeGames()
        let apex = games.first { $0.name == "Apex Legends" }!
        let lol = games.first { $0.name == "LOL" }!
        let valorant = games.first { $0.name == "Valorant" }!

        let arranger = GameArranger(
            sessionRepository: StubSessionRepository(
                endedSessions: [
                    makeSession(
                        gameID: apex.id,
                        startAt: Date(timeIntervalSince1970: 1_700_000_000),
                        endAt: Date(timeIntervalSince1970: 1_700_000_900)
                    ),
                    makeSession(
                        gameID: valorant.id,
                        startAt: Date(timeIntervalSince1970: 1_699_999_000),
                        endAt: Date(timeIntervalSince1970: 1_699_999_700)
                    ),
                    makeSession(
                        gameID: valorant.id,
                        startAt: Date(timeIntervalSince1970: 1_699_998_000),
                        endAt: Date(timeIntervalSince1970: 1_699_998_600)
                    ),
                    makeSession(
                        gameID: lol.id,
                        startAt: Date(timeIntervalSince1970: 1_699_997_000),
                        endAt: Date(timeIntervalSince1970: 1_699_997_500)
                    )
                ]
            )
        )

        let orderedGames = try arranger.getWeightedGameList(from: games)

        #expect(orderedGames.map(\.name) == ["Apex Legends", "Valorant", "LOL"])
    }
}

@MainActor
private final class StubSessionRepository: SessionRepository {
    private let endedSessions: [SessionEntity]

    init(endedSessions: [SessionEntity]) {
        self.endedSessions = endedSessions
    }

    func create(
        startAt: Date,
        endAt: Date?,
        platform: Platform,
        gameID: UUID?,
        durationSeconds: Int?,
        note: String?,
        friendIDs: [UUID]
    ) throws -> SessionEntity {
        fatalError("Unused in GameArrangerTests")
    }

    func update(_ session: SessionEntity) throws -> SessionEntity {
        fatalError("Unused in GameArrangerTests")
    }

    func fetch(id: UUID) throws -> SessionEntity? {
        fatalError("Unused in GameArrangerTests")
    }

    func fetchEnded(between start: Date, and end: Date) throws -> [SessionEntity] {
        endedSessions.filter { session in
            guard let endAt = session.endAt else { return false }
            return endAt >= start && endAt <= end
        }
    }

    func delete(id: UUID) throws {
        fatalError("Unused in GameArrangerTests")
    }
}

private func makeGames() -> [GameEntity] {
    [
        GameEntity(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Valorant"),
        GameEntity(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "LOL"),
        GameEntity(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Apex Legends")
    ]
}

private func makeSession(gameID: UUID, startAt: Date, endAt: Date) -> SessionEntity {
    SessionEntity(
        id: UUID(),
        startAt: startAt,
        endAt: endAt,
        durationSeconds: Int(endAt.timeIntervalSince(startAt)),
        platform: .pc,
        gameID: gameID,
        note: nil,
        friendIDs: []
    )
}
