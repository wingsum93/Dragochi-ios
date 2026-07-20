//
//  FriendListArrangeManagerTests.swift
//  DragochiTests
//
//  Created by Codex on 8/3/2026.
//

import Foundation
import Testing
@testable import Dragochi

struct FriendListArrangeManagerTests {
    @Test
    @MainActor
    func getFriendList_returnsAlphabeticalOrderWhenNoSessionsExist() throws {
        let friends = makeFriends(names: ["John", "Baby", "Alex", "Chris"])
        let manager = FriendListArrangeManager(
            sessionRepository: FakeSessionRepository(),
            friendRepository: FakeFriendRepository(friends: friends)
        )

        let orderedFriends = try manager.getFriendList()

        #expect(orderedFriends.map(\.name) == ["Alex", "Baby", "Chris", "John"])
    }

    @Test
    @MainActor
    func getFriendList_placesFriendFromLongerSessionFirst() throws {
        let alex = FriendEntity(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Alex")
        let baby = FriendEntity(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Baby")
        let manager = FriendListArrangeManager(
            sessionRepository: FakeSessionRepository(
                sessions: [
                    makeSession(
                        startAt: Date(timeIntervalSince1970: 1_700_000_000),
                        endAt: Date(timeIntervalSince1970: 1_700_003_600),
                        friendIDs: [baby.id]
                    ),
                    makeSession(
                        startAt: Date(timeIntervalSince1970: 1_700_004_000),
                        endAt: Date(timeIntervalSince1970: 1_700_004_600),
                        friendIDs: [alex.id]
                    )
                ]
            ),
            friendRepository: FakeFriendRepository(friends: [alex, baby])
        )

        let orderedFriends = try manager.getFriendList()

        #expect(orderedFriends.map(\.name) == ["Baby", "Alex"])
    }

    @Test
    @MainActor
    func getFriendList_prioritizesFriendsWithHighestTotalPlaytimeAcrossManySessions() throws {
        let baby = FriendEntity(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Baby")
        let john = FriendEntity(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "John")
        let alex = FriendEntity(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Alex")
        let ben = FriendEntity(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, name: "Ben")
        let cara = FriendEntity(id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!, name: "Cara")
        let dylan = FriendEntity(id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!, name: "Dylan")

        let wwzSessions = (0..<4).map { index in
            makeSession(
                startAt: Date(timeIntervalSince1970: 1_700_000_000 + TimeInterval(index * 10_000)),
                endAt: Date(timeIntervalSince1970: 1_700_003_600 + TimeInterval(index * 10_000)),
                friendIDs: [alex.id, ben.id, cara.id, dylan.id]
            )
        }
        let apexSessions = (0..<6).map { index in
            makeSession(
                startAt: Date(timeIntervalSince1970: 1_700_100_000 + TimeInterval(index * 10_000)),
                endAt: Date(timeIntervalSince1970: 1_700_103_600 + TimeInterval(index * 10_000)),
                friendIDs: [baby.id, john.id]
            )
        }

        let manager = FriendListArrangeManager(
            sessionRepository: FakeSessionRepository(sessions: wwzSessions + apexSessions),
            friendRepository: FakeFriendRepository(friends: [baby, john, alex, ben, cara, dylan])
        )

        let orderedFriends = try manager.getFriendList()

        #expect(orderedFriends.map(\.name) == ["Baby", "John", "Alex", "Ben", "Cara", "Dylan"])
    }
}

private func makeFriends(names: [String]) -> [FriendEntity] {
    names.enumerated().map { index, name in
        FriendEntity(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!,
            name: name
        )
    }
}

private func makeSession(startAt: Date, endAt: Date, friendIDs: [UUID]) -> SessionEntity {
    SessionEntity(
        id: UUID(),
        startAt: startAt,
        endAt: endAt,
        durationSeconds: Int(endAt.timeIntervalSince(startAt)),
        platform: .pc,
        gameID: nil,
        note: nil,
        friendIDs: friendIDs
    )
}
