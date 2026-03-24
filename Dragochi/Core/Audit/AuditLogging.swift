//
//  AuditLogging.swift
//  Dragochi
//
//  Created by Codex on 23/3/2026.
//

import Foundation

enum AuditAction: String, Codable {
    case mainTrackingStarted
    case mainTrackingPaused
    case mainTrackingResumed
    case mainTrackingStopped
    case mainTrackingSnapshotRestored

    case addSessionPreStartConfirmed
    case addSessionManualSaved

    case friendAdded
    case friendEdited
    case friendDeleted
    case friendReordered

    case gameSettingsChangesSaved

    case settingsExported
    case settingsImported

    case appleContactsImported
    case appleDuplicateImportConfirmed
}

enum AuditOutcome: String, Codable {
    case success
    case failure
}

struct AuditRecord: Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let action: AuditAction
    let outcome: AuditOutcome
    let metadata: [String: String]
}

@MainActor
protocol AuditLogging {
    var auditLogFileURL: URL? { get }
    func log(action: AuditAction, outcome: AuditOutcome, metadata: [String: String])
}

extension AuditLogging {
    var auditLogFileURL: URL? { nil }

    func log(action: AuditAction, outcome: AuditOutcome) {
        log(action: action, outcome: outcome, metadata: [:])
    }
}

enum AuditMetadata {
    static func bool(_ value: Bool) -> String {
        value ? "true" : "false"
    }

    static func withError(
        _ base: [String: String] = [:],
        error: Error
    ) -> [String: String] {
        let nsError = error as NSError
        var metadata = base
        metadata["error_domain"] = nsError.domain
        metadata["error_code"] = String(nsError.code)
        return metadata
    }
}
