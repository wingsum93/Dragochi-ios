//
//  MainStore.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import Combine

@MainActor
final class MainStore: ObservableObject {
    enum TrackingStatus: String, Codable, Equatable {
        case idle
        case running
        case paused
    }

    struct TrackingSessionSnapshot: Codable, Equatable {
        let sessionID: UUID
        let startAt: Date
        let setup: SessionSetupInput
        let accumulatedActiveSeconds: Int
        let activeSegmentStartedAt: Date?
        let status: TrackingStatus
    }

    struct State: Equatable {
        var trackingStatus: TrackingStatus = .idle
        var elapsedSeconds: Int = 0
        var currentSessionID: UUID?
        var trackingStartAt: Date?
        var activeSegmentStartedAt: Date?
        var accumulatedActiveSeconds: Int = 0
        var activeSetup: SessionSetupInput?
        var games: [GameEntity] = []
        var friends: [FriendEntity] = []
        var latestEndedSession: SessionEntity?
        var pendingAddSessionDraft: AddSessionDraft?
        var trackingSnapshotData: Data?
        var errorMessage: String?
    }

    enum Action {
        case onAppear
        case startTapped(resumeLastSetupEnabled: Bool)
        case preStartSetupConfirmed(SessionSetupInput)
        case pauseResumeTapped
        case stopTapped
        case tick
        case restoreTrackingSnapshot(Data?)
        case clearPendingDraft
    }

    @Published private(set) var state = State()

    private let sessionRepository: SessionRepository
    private let gameRepository: GameRepository
    private let friendRepository: FriendRepository
    private let gameCatalogSyncService: GameCatalogSyncService
    private let auditLogger: AuditLogging
    private let now: () -> Date
    private let isUITesting: Bool
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(dependencies: AppDependencies, now: @escaping () -> Date = Date.init) {
        self.sessionRepository = dependencies.sessionRepository
        self.gameRepository = dependencies.gameRepository
        self.friendRepository = dependencies.friendRepository
        self.gameCatalogSyncService = dependencies.gameCatalogSyncService
        self.auditLogger = dependencies.auditLogger
        self.now = now
        self.isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            loadInitialData()
        case .startTapped(let resumeLastSetupEnabled):
            handleStartTapped(resumeLastSetupEnabled: resumeLastSetupEnabled)
        case .preStartSetupConfirmed(let setup):
            startTracking(with: setup)
        case .pauseResumeTapped:
            handlePauseResume()
        case .stopTapped:
            stopTracking()
        case .tick:
            state.elapsedSeconds = currentElapsedSeconds(at: now())
        case .restoreTrackingSnapshot(let data):
            restoreTrackingSnapshot(from: data)
        case .clearPendingDraft:
            state.pendingAddSessionDraft = nil
        }
    }

    private func handleStartTapped(resumeLastSetupEnabled: Bool) {
        guard state.trackingStatus == .idle else { return }

        if resumeLastSetupEnabled, let setup = latestSetupFromEndedSession() {
            startTracking(with: setup)
            return
        }

        let draftDate = now()
        state.pendingAddSessionDraft = AddSessionDraft(
            id: UUID(),
            mode: .preStartSetup,
            sessionID: nil,
            startAt: draftDate,
            endAt: draftDate,
            selectedGameID: nil,
            selectedPlatform: .pc,
            selectedFriendIDs: [],
            note: ""
        )
    }

    private func loadInitialData() {
        do {
            _ = try gameCatalogSyncService.seedFromFallbackIfNeeded()
            state.games = try sortedGames()
            state.friends = try friendRepository.fetchActive()
            state.latestEndedSession = try fetchLatestEndedSession()

            guard !isUITesting else { return }
            Task { [weak self] in
                await self?.refreshCatalogFromRemote()
            }
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func startTracking(with setup: SessionSetupInput) {
        guard state.trackingStatus == .idle else { return }

        let startAt = now()
        let baseMetadata: [String: String] = [
            "platform": setup.selectedPlatform.rawValue,
            "game_id": setup.selectedGameID.uuidString,
            "friend_count": String(setup.selectedFriendIDs.count)
        ]
        do {
            let created = try sessionRepository.create(
                startAt: startAt,
                endAt: nil,
                platform: setup.selectedPlatform,
                gameID: setup.selectedGameID,
                durationSeconds: nil,
                note: setup.note.isEmpty ? nil : setup.note,
                friendIDs: setup.selectedFriendIDs
            )

            state.currentSessionID = created.id
            state.trackingStartAt = startAt
            state.activeSegmentStartedAt = startAt
            state.accumulatedActiveSeconds = 0
            state.elapsedSeconds = 0
            state.activeSetup = setup
            state.trackingStatus = .running
            syncTrackingSnapshotData()
            auditLogger.log(
                action: .mainTrackingStarted,
                outcome: .success,
                metadata: baseMetadata.merging(["session_id": created.id.uuidString], uniquingKeysWith: { _, new in new })
            )
        } catch {
            state.errorMessage = error.localizedDescription
            auditLogger.log(
                action: .mainTrackingStarted,
                outcome: .failure,
                metadata: AuditMetadata.withError(baseMetadata, error: error)
            )
        }
    }

    private func handlePauseResume() {
        switch state.trackingStatus {
        case .idle:
            return
        case .running:
            guard let activeSegmentStartedAt = state.activeSegmentStartedAt else { return }
            let additional = max(0, Int(now().timeIntervalSince(activeSegmentStartedAt)))
            state.accumulatedActiveSeconds += additional
            state.activeSegmentStartedAt = nil
            state.trackingStatus = .paused
            state.elapsedSeconds = state.accumulatedActiveSeconds
            syncTrackingSnapshotData()
            auditLogger.log(
                action: .mainTrackingPaused,
                outcome: .success,
                metadata: [
                    "session_id": state.currentSessionID?.uuidString ?? "",
                    "elapsed_seconds": String(state.elapsedSeconds)
                ]
            )
        case .paused:
            state.activeSegmentStartedAt = now()
            state.trackingStatus = .running
            syncTrackingSnapshotData()
            auditLogger.log(
                action: .mainTrackingResumed,
                outcome: .success,
                metadata: [
                    "session_id": state.currentSessionID?.uuidString ?? "",
                    "elapsed_seconds": String(state.elapsedSeconds)
                ]
            )
        }
    }

    private func stopTracking() {
        guard state.trackingStatus != .idle else { return }
        guard
            let sessionID = state.currentSessionID,
            let startAt = state.trackingStartAt,
            let setup = state.activeSetup
        else { return }

        let endAt = now()
        let durationSeconds = currentElapsedSeconds(at: endAt)

        let session = SessionEntity(
            id: sessionID,
            startAt: startAt,
            endAt: endAt,
            durationSeconds: durationSeconds,
            platform: setup.selectedPlatform,
            gameID: setup.selectedGameID,
            note: setup.note.isEmpty ? nil : setup.note,
            friendIDs: setup.selectedFriendIDs
        )

        do {
            _ = try sessionRepository.update(session)
            state.latestEndedSession = session
            state.elapsedSeconds = durationSeconds
            clearTrackingState(resetElapsed: false)
            auditLogger.log(
                action: .mainTrackingStopped,
                outcome: .success,
                metadata: [
                    "session_id": sessionID.uuidString,
                    "duration_seconds": String(durationSeconds),
                    "platform": setup.selectedPlatform.rawValue,
                    "friend_count": String(setup.selectedFriendIDs.count)
                ]
            )
        } catch {
            state.errorMessage = error.localizedDescription
            auditLogger.log(
                action: .mainTrackingStopped,
                outcome: .failure,
                metadata: AuditMetadata.withError(
                    [
                        "session_id": sessionID.uuidString,
                        "duration_seconds": String(durationSeconds),
                        "platform": setup.selectedPlatform.rawValue,
                        "friend_count": String(setup.selectedFriendIDs.count)
                    ],
                    error: error
                )
            )
        }
    }

    private func restoreTrackingSnapshot(from data: Data?) {
        guard state.currentSessionID == nil else { return }
        guard let data else { return }

        do {
            let snapshot = try decoder.decode(TrackingSessionSnapshot.self, from: data)
            guard snapshot.status != .idle else { return }

            state.currentSessionID = snapshot.sessionID
            state.trackingStartAt = snapshot.startAt
            state.activeSetup = snapshot.setup
            state.accumulatedActiveSeconds = max(0, snapshot.accumulatedActiveSeconds)
            state.activeSegmentStartedAt = snapshot.activeSegmentStartedAt
            state.trackingStatus = snapshot.status
            state.elapsedSeconds = currentElapsedSeconds(at: now())
            state.trackingSnapshotData = data
        } catch {
            state.errorMessage = error.localizedDescription
            state.trackingSnapshotData = nil
            auditLogger.log(
                action: .mainTrackingSnapshotRestored,
                outcome: .failure,
                metadata: AuditMetadata.withError(
                    [
                        "has_snapshot_data": AuditMetadata.bool(true)
                    ],
                    error: error
                )
            )
        }
    }

    private func clearTrackingState(resetElapsed: Bool) {
        state.currentSessionID = nil
        state.trackingStartAt = nil
        state.activeSegmentStartedAt = nil
        state.accumulatedActiveSeconds = 0
        state.activeSetup = nil
        state.trackingStatus = .idle
        if resetElapsed {
            state.elapsedSeconds = 0
        }
        state.trackingSnapshotData = nil
    }

    private func currentElapsedSeconds(at date: Date) -> Int {
        switch state.trackingStatus {
        case .idle:
            return state.elapsedSeconds
        case .paused:
            return max(0, state.accumulatedActiveSeconds)
        case .running:
            guard let activeSegmentStartedAt = state.activeSegmentStartedAt else {
                return max(0, state.accumulatedActiveSeconds)
            }
            let segment = max(0, Int(date.timeIntervalSince(activeSegmentStartedAt)))
            return max(0, state.accumulatedActiveSeconds + segment)
        }
    }

    private func syncTrackingSnapshotData() {
        guard
            let sessionID = state.currentSessionID,
            let startAt = state.trackingStartAt,
            let setup = state.activeSetup,
            state.trackingStatus != .idle
        else {
            state.trackingSnapshotData = nil
            return
        }

        let snapshot = TrackingSessionSnapshot(
            sessionID: sessionID,
            startAt: startAt,
            setup: setup,
            accumulatedActiveSeconds: max(0, state.accumulatedActiveSeconds),
            activeSegmentStartedAt: state.activeSegmentStartedAt,
            status: state.trackingStatus
        )

        state.trackingSnapshotData = try? encoder.encode(snapshot)
    }

    private func refreshCatalogFromRemote() async {
        do {
            _ = try await gameCatalogSyncService.refreshFromRemote()
            state.games = try sortedGames()
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func fetchLatestEndedSession() throws -> SessionEntity? {
        let endedSessions = try sessionRepository.fetchEnded(between: .distantPast, and: now())
        return endedSessions.sorted { lhs, rhs in
            let lhsDate = lhs.endAt ?? lhs.startAt
            let rhsDate = rhs.endAt ?? rhs.startAt
            if lhsDate == rhsDate {
                return lhs.startAt > rhs.startAt
            }
            return lhsDate > rhsDate
        }.first
    }

    private func sortedGames() throws -> [GameEntity] {
        try gameRepository.fetchAll()
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    private func latestSetupFromEndedSession() -> SessionSetupInput? {
        guard
            let latestEndedSession = state.latestEndedSession,
            let selectedGameID = latestEndedSession.gameID
        else {
            return nil
        }

        let activeFriendIDs = Set(state.friends.map(\.id))
        let selectedFriendIDs = latestEndedSession.friendIDs.reduce(into: [UUID]()) { selected, friendID in
            guard activeFriendIDs.contains(friendID) else { return }
            guard !selected.contains(friendID) else { return }
            selected.append(friendID)
        }

        return SessionSetupInput(
            selectedGameID: selectedGameID,
            selectedPlatform: latestEndedSession.platform,
            selectedFriendIDs: selectedFriendIDs,
            note: ""
        )
    }

}
