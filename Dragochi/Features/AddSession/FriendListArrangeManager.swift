//
//  FriendListArrangeManager.swift
//  Dragochi
//
//  Created by Codex on 8/3/2026.
//

import Foundation

@MainActor
final class FriendListArrangeManager {
    private let sessionRepository: SessionRepository
    private let friendRepository: FriendRepository

    init(sessionRepository: SessionRepository, friendRepository: FriendRepository) {
        self.sessionRepository = sessionRepository
        self.friendRepository = friendRepository
    }

    func getFriendList() throws -> [FriendEntity] {
        let defaultOrderedFriends = try friendRepository.fetchActive().sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }

        guard !defaultOrderedFriends.isEmpty else { return [] }

        let activeFriendIDs = Set(defaultOrderedFriends.map(\.id))
        let sessions = try sessionRepository.fetchEnded(between: .distantPast, and: .distantFuture)

        var durationByFriendID: [UUID: Int] = [:]
        for session in sessions where !session.friendIDs.isEmpty {
            let duration = session.durationSeconds ?? Self.computeDurationSeconds(for: session)
            let uniqueFriendIDs = Set(session.friendIDs).intersection(activeFriendIDs)

            for friendID in uniqueFriendIDs {
                durationByFriendID[friendID, default: 0] += duration
            }
        }

        return defaultOrderedFriends.sorted { lhs, rhs in
            let lhsDuration = durationByFriendID[lhs.id, default: 0]
            let rhsDuration = durationByFriendID[rhs.id, default: 0]

            if lhsDuration != rhsDuration {
                return lhsDuration > rhsDuration
            }

            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private static func computeDurationSeconds(for session: SessionEntity) -> Int {
        guard let endAt = session.endAt else { return 0 }
        return max(0, Int(endAt.timeIntervalSince(session.startAt)))
    }
}
