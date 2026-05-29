//
//  AuditViewModelLoggingTests.swift
//  DragochiTests
//
//  Created by Codex on 23/3/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Dragochi

@MainActor
private final class SpyAuditLogger: AuditLogging {
    struct Entry {
        let action: AuditAction
        let outcome: AuditOutcome
        let metadata: [String: String]
    }

    private(set) var entries: [Entry] = []

    func log(action: AuditAction, outcome: AuditOutcome, metadata: [String: String]) {
        entries.append(Entry(action: action, outcome: outcome, metadata: metadata))
    }
}

struct AuditViewModelLoggingTests {
    @Test
    func mainStore_logsTrackingLifecycleSuccessEvents() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let spyLogger = SpyAuditLogger()
            let dependencies = AppDependencies(
                modelContext: ModelContext(container),
                auditLogger: spyLogger
            )
            var current = Date(timeIntervalSince1970: 1_700_000_000)
            let viewModel = MainViewModel(dependencies: dependencies, now: { current })

            viewModel.send(.onAppear)
            guard let selectedGameID = viewModel.state.games.first?.id else {
                Issue.record("Expected at least one game for main viewModel tracking test.")
                return
            }

            let setup = SessionSetupInput(
                selectedGameID: selectedGameID,
                selectedPlatform: .pc,
                selectedFriendIDs: [],
                note: "this note should never appear in audit metadata"
            )

            viewModel.send(.preStartSetupConfirmed(setup))
            viewModel.send(.pauseResumeTapped)
            viewModel.send(.pauseResumeTapped)
            current = current.addingTimeInterval(10)
            viewModel.send(.tick)
            viewModel.send(.stopTapped)

            #expect(spyLogger.entries.contains { $0.action == .mainTrackingStarted && $0.outcome == .success })
            #expect(spyLogger.entries.contains { $0.action == .mainTrackingPaused && $0.outcome == .success })
            #expect(spyLogger.entries.contains { $0.action == .mainTrackingResumed && $0.outcome == .success })
            #expect(spyLogger.entries.contains { $0.action == .mainTrackingStopped && $0.outcome == .success })
        }
    }

    @Test
    func mainStore_logsSnapshotRestoreFailure() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let spyLogger = SpyAuditLogger()
            let dependencies = AppDependencies(
                modelContext: ModelContext(container),
                auditLogger: spyLogger
            )
            let viewModel = MainViewModel(dependencies: dependencies)

            viewModel.send(.restoreTrackingSnapshot(Data("invalid-json".utf8)))

            #expect(
                spyLogger.entries.contains {
                    $0.action == .mainTrackingSnapshotRestored &&
                    $0.outcome == .failure &&
                    $0.metadata["error_domain"] != nil &&
                    $0.metadata["error_code"] != nil
                }
            )
        }
    }

    @Test
    func addSessionStore_logsManualSaveSuccessAndExcludesNoteText() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let spyLogger = SpyAuditLogger()
            let dependencies = AppDependencies(
                modelContext: ModelContext(container),
                auditLogger: spyLogger
            )
            let secretNote = "PRIVATE_AUDIT_NOTE_SHOULD_NOT_BE_LOGGED"
            let draft = AddSessionDraft(
                id: UUID(),
                mode: .manualEntry,
                sessionID: nil,
                startAt: Date(timeIntervalSince1970: 1_700_000_000),
                endAt: Date(timeIntervalSince1970: 1_700_000_900),
                selectedGameID: nil,
                selectedPlatform: .pc,
                selectedFriendIDs: [],
                note: secretNote
            )

            let viewModel = AddSessionViewModel(dependencies: dependencies, draft: draft)
            viewModel.send(.onAppear)
            viewModel.send(.saveTapped)

            guard let entry = spyLogger.entries.last(where: {
                $0.action == .addSessionManualSaved && $0.outcome == .success
            }) else {
                Issue.record("Expected successful manual save audit entry.")
                return
            }

            #expect(entry.metadata["has_note"] == "true")
            #expect(!entry.metadata.values.contains(where: { $0.contains(secretNote) }))
        }
    }

    @Test
    func addSessionStore_logsPreStartFailureWhenGameMissing() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let spyLogger = SpyAuditLogger()
            let dependencies = AppDependencies(
                modelContext: ModelContext(container),
                auditLogger: spyLogger
            )

            let draft = AddSessionDraft(
                id: UUID(),
                mode: .preStartSetup,
                sessionID: nil,
                startAt: Date(timeIntervalSince1970: 1_700_000_000),
                endAt: Date(timeIntervalSince1970: 1_700_000_100),
                selectedGameID: nil,
                selectedPlatform: .pc,
                selectedFriendIDs: [],
                note: ""
            )

            let viewModel = AddSessionViewModel(dependencies: dependencies, draft: draft)
            viewModel.send(.saveTapped)

            #expect(
                spyLogger.entries.contains {
                    $0.action == .addSessionPreStartConfirmed &&
                    $0.outcome == .failure &&
                    $0.metadata["reason"] == "missing_game"
                }
            )
        }
    }
}
