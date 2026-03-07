//
//  GameArranger.swift
//  Dragochi
//
//  Created by Codex on 8/3/2026.
//

import Foundation

@MainActor
final class GameArranger {
    private let sessionRepository: SessionRepository

    init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    func getWeightedGameList(from games: [GameEntity]) throws -> [GameEntity] {
        let defaultOrderedGames = games.sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }

        guard !defaultOrderedGames.isEmpty else { return [] }

        let gameIDs = Set(defaultOrderedGames.map(\.id))
        let sessions = try sessionRepository.fetchEnded(between: .distantPast, and: .distantFuture)
        let relevantSessions = sessions.filter { session in
            guard let gameID = session.gameID else { return false }
            return gameIDs.contains(gameID)
        }

        guard let mostRecentGameID = relevantSessions.first?.gameID else {
            return defaultOrderedGames
        }

        var scoreByGameID: [UUID: (durationSeconds: Int, count: Int)] = [:]
        for session in relevantSessions {
            guard let gameID = session.gameID else { continue }
            let duration = session.durationSeconds ?? 0
            let current = scoreByGameID[gameID] ?? (durationSeconds: 0, count: 0)
            scoreByGameID[gameID] = (
                durationSeconds: current.durationSeconds + duration,
                count: current.count + 1
            )
        }

        let defaultIndexByGameID = Dictionary(
            uniqueKeysWithValues: defaultOrderedGames.enumerated().map { ($0.element.id, $0.offset) }
        )

        let remainingGames = defaultOrderedGames
            .filter { $0.id != mostRecentGameID }
            .sorted { lhs, rhs in
                let lhsScore = scoreByGameID[lhs.id] ?? (durationSeconds: 0, count: 0)
                let rhsScore = scoreByGameID[rhs.id] ?? (durationSeconds: 0, count: 0)

                if lhsScore.durationSeconds != rhsScore.durationSeconds {
                    return lhsScore.durationSeconds > rhsScore.durationSeconds
                }

                if lhsScore.count != rhsScore.count {
                    return lhsScore.count > rhsScore.count
                }

                return (defaultIndexByGameID[lhs.id] ?? 0) < (defaultIndexByGameID[rhs.id] ?? 0)
            }

        guard let mostRecentGame = defaultOrderedGames.first(where: { $0.id == mostRecentGameID }) else {
            return defaultOrderedGames
        }

        return [mostRecentGame] + remainingGames
    }
}
