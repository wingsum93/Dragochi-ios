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
            sessionRepository: StubSessionRepository(endedSessions: []),
            friendRepository: StubFriendRepository(activeFriends: friends)
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
            sessionRepository: StubSessionRepository(
                endedSessions: [
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
            friendRepository: StubFriendRepository(activeFriends: [alex, baby])
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
            sessionRepository: StubSessionRepository(endedSessions: wwzSessions + apexSessions),
            friendRepository: StubFriendRepository(activeFriends: [baby, john, alex, ben, cara, dylan])
        )

        let orderedFriends = try manager.getFriendList()

        #expect(orderedFriends.map(\.name) == ["Baby", "John", "Alex", "Ben", "Cara", "Dylan"])
    }
}

@MainActor
private final class StubFriendRepository: FriendRepository {
    private let activeFriends: [FriendEntity]

    init(activeFriends: [FriendEntity]) {
        self.activeFriends = activeFriends
    }

    func create(
        name: String,
        handle: String?,
        avatarAssetName: String?,
        isActive: Bool
    ) throws -> FriendEntity {
        fatalError("Unused in FriendListArrangeManagerTests")
    }

    func upsert(_ friend: FriendEntity) throws -> FriendEntity {
        fatalError("Unused in FriendListArrangeManagerTests")
    }

    func fetch(id: UUID) throws -> FriendEntity? {
        activeFriends.first { $0.id == id }
    }

    func fetchActive() throws -> [FriendEntity] {
        activeFriends
    }

    func fetchAll() throws -> [FriendEntity] {
        activeFriends
    }

    func delete(id: UUID) throws {
        fatalError("Unused in FriendListArrangeManagerTests")
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
        fatalError("Unused in FriendListArrangeManagerTests")
    }

    func update(_ session: SessionEntity) throws -> SessionEntity {
        fatalError("Unused in FriendListArrangeManagerTests")
    }

    func fetch(id: UUID) throws -> SessionEntity? {
        fatalError("Unused in FriendListArrangeManagerTests")
    }

    func fetchEnded(between start: Date, and end: Date) throws -> [SessionEntity] {
        endedSessions.filter { session in
            guard let endAt = session.endAt else { return false }
            return endAt >= start && endAt <= end
        }
    }

    func delete(id: UUID) throws {
        fatalError("Unused in FriendListArrangeManagerTests")
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
