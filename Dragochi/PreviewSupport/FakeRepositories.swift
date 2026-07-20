//
//  FakeRepositories.swift
//  Dragochi
//
//  Created by Codex on 21/7/2026.
//

#if DEBUG
import Foundation

@MainActor
final class FakeSessionRepository: SessionRepository {
    private var sessions: [SessionEntity]

    init(sessions: [SessionEntity] = []) {
        self.sessions = sessions
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
        let session = SessionEntity(
            startAt: startAt,
            endAt: endAt,
            durationSeconds: durationSeconds,
            platform: platform,
            gameID: gameID,
            note: note,
            friendIDs: friendIDs
        )
        sessions.insert(session, at: 0)
        return session
    }

    func update(_ session: SessionEntity) throws -> SessionEntity {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.insert(session, at: 0)
        }
        return session
    }

    func fetch(id: UUID) throws -> SessionEntity? {
        sessions.first { $0.id == id }
    }

    func fetchEnded(between start: Date, and end: Date) throws -> [SessionEntity] {
        sessions.filter { session in
            guard let endAt = session.endAt else { return false }
            return endAt >= start && endAt <= end
        }
    }

    func delete(id: UUID) throws {
        sessions.removeAll { $0.id == id }
    }
}

@MainActor
final class FakeGameRepository: GameRepository {
    private var games: [GameEntity]
    private var referencedIDs: Set<UUID>

    init(games: [GameEntity] = [], referencedGameIDs: Set<UUID> = []) {
        self.games = games
        self.referencedIDs = referencedGameIDs
    }

    func create(name: String, imageAssetName: String?, remoteID: String?) throws -> GameEntity {
        let game = GameEntity(name: name, imageAssetName: imageAssetName, remoteID: remoteID)
        games.append(game)
        return game
    }

    func upsert(_ game: GameEntity) throws -> GameEntity {
        if let index = games.firstIndex(where: { $0.id == game.id }) {
            games[index] = game
        } else {
            games.append(game)
        }
        return game
    }

    func fetch(id: UUID) throws -> GameEntity? {
        games.first { $0.id == id }
    }

    func fetch(remoteID: String) throws -> GameEntity? {
        games.first { $0.remoteID == remoteID }
    }

    func fetchAll() throws -> [GameEntity] {
        games
    }

    func referencedGameIDs() throws -> Set<UUID> {
        referencedIDs
    }

    func delete(id: UUID) throws {
        games.removeAll { $0.id == id }
        referencedIDs.remove(id)
    }
}

@MainActor
final class FakeFriendRepository: FriendRepository {
    private var friends: [FriendEntity]

    init(friends: [FriendEntity] = []) {
        self.friends = friends
    }

    func create(
        name: String,
        handle: String?,
        avatarAssetName: String?,
        isActive: Bool,
        order: Int,
        note: String?
    ) throws -> FriendEntity {
        let friend = FriendEntity(
            name: name,
            handle: handle,
            avatarAssetName: avatarAssetName,
            isActive: isActive,
            order: order,
            note: note
        )
        friends.append(friend)
        return friend
    }

    func upsert(_ friend: FriendEntity) throws -> FriendEntity {
        if let index = friends.firstIndex(where: { $0.id == friend.id }) {
            friends[index] = friend
        } else {
            friends.append(friend)
        }
        return friend
    }

    func fetch(id: UUID) throws -> FriendEntity? {
        friends.first { $0.id == id }
    }

    func fetchActive() throws -> [FriendEntity] {
        friends.filter(\.isActive)
    }

    func fetchAll() throws -> [FriendEntity] {
        friends
    }

    func delete(id: UUID) throws {
        friends.removeAll { $0.id == id }
    }
}

@MainActor
final class FakeEnabledGameSelectionRepository: EnabledGameSelectionRepository {
    private var enabledRemoteIDs: Set<String>

    init(enabledRemoteIDs: Set<String> = []) {
        self.enabledRemoteIDs = enabledRemoteIDs
    }

    func fetchEnabledRemoteIDs() throws -> Set<String> {
        enabledRemoteIDs
    }

    func enable(remoteID: String) throws {
        enabledRemoteIDs.insert(remoteID)
    }

    func disable(remoteID: String) throws {
        enabledRemoteIDs.remove(remoteID)
    }

    func removeMissing(remoteIDs: Set<String>) throws {
        enabledRemoteIDs = enabledRemoteIDs.intersection(remoteIDs)
    }
}
#endif
