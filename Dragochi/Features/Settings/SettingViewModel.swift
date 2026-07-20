//
//  SettingViewModel.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import Combine
import UIKit

struct IssueReportDraft: Identifiable, Equatable {
    let id: UUID
    let recipient: String
    let subject: String
    let body: String
    let attachmentURL: URL?
    let attachmentFileName: String
    let attachmentMimeType: String
}

enum SettingsPresentation: Identifiable, Equatable {
    case openSourceLicenses
    case friendImportOptions
    case appleFriendImport
    case googleImportComingSoon
    case issueReport(IssueReportDraft)
    case mailUnavailable

    var id: String {
        switch self {
        case .openSourceLicenses:
            return "openSourceLicenses"
        case .friendImportOptions:
            return "friendImportOptions"
        case .appleFriendImport:
            return "appleFriendImport"
        case .googleImportComingSoon:
            return "googleImportComingSoon"
        case .issueReport(let draft):
            return "issueReport.\(draft.id.uuidString)"
        case .mailUnavailable:
            return "mailUnavailable"
        }
    }
}

@MainActor
final class SettingViewModel: ObservableObject {
    static let reportIssueRecipientEmail = "wingsum.developer@gmail.com"
    private static let reportIssueSubject = "Dragochi Issue Report"

    struct State: Equatable {
        var isICloudSyncOn: Bool = false
        var lastBackupDate: Date?
        var isExporting: Bool = false
        var isImporting: Bool = false
        var presentation: SettingsPresentation?
        var errorMessage: String?

        var issueReportDraft: IssueReportDraft? {
            guard case .issueReport(let draft) = presentation else { return nil }
            return draft
        }

        var isShowingMailUnavailableAlert: Bool {
            presentation == .mailUnavailable
        }
    }

    enum Action {
        case onAppear
        case toggleICloud(Bool)
        case exportTapped
        case importTapped
        case openSourceLicensesTapped
        case friendImportOptionsTapped
        case appleFriendImportSelected
        case googleFriendImportSelected
        case reportIssueTapped(canSendMail: Bool)
        case clearPresentation
        case clearIssueReportDraft
        case dismissMailUnavailableAlert
    }

    @Published private(set) var state = State()

    private let backupService: BackupService
    private let auditLogger: AuditLogging

    init(backupService: BackupService, auditLogger: AuditLogging) {
        self.backupService = backupService
        self.auditLogger = auditLogger
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            break
        case .toggleICloud(let isOn):
            state.isICloudSyncOn = isOn
        case .exportTapped:
            exportBackup()
        case .importTapped:
            importBackup()
        case .openSourceLicensesTapped:
            state.presentation = .openSourceLicenses
        case .friendImportOptionsTapped:
            state.presentation = .friendImportOptions
        case .appleFriendImportSelected:
            state.presentation = .appleFriendImport
        case .googleFriendImportSelected:
            state.presentation = .googleImportComingSoon
        case .reportIssueTapped(let canSendMail):
            prepareIssueReport(canSendMail: canSendMail)
        case .clearPresentation, .clearIssueReportDraft, .dismissMailUnavailableAlert:
            state.presentation = nil
        }
    }

    private func exportBackup() {
        state.isExporting = true
        defer { state.isExporting = false }
        do {
            let payload = try backupService.export()
            state.lastBackupDate = payload.exportedAt
            auditLogger.log(
                action: .settingsExported,
                outcome: .success,
                metadata: [
                    "games_count": String(payload.games.count),
                    "friends_count": String(payload.friends.count),
                    "sessions_count": String(payload.sessions.count)
                ]
            )
        } catch {
            state.errorMessage = error.localizedDescription
            auditLogger.log(
                action: .settingsExported,
                outcome: .failure,
                metadata: AuditMetadata.withError(error: error)
            )
        }
    }

    private func importBackup() {
        state.isImporting = true
        defer { state.isImporting = false }
        do {
            let payload = BackupPayload(games: [], friends: [], sessions: [])
            try backupService.import(payload)
            auditLogger.log(
                action: .settingsImported,
                outcome: .success,
                metadata: [
                    "games_count": String(payload.games.count),
                    "friends_count": String(payload.friends.count),
                    "sessions_count": String(payload.sessions.count)
                ]
            )
        } catch {
            state.errorMessage = error.localizedDescription
            auditLogger.log(
                action: .settingsImported,
                outcome: .failure,
                metadata: AuditMetadata.withError(error: error)
            )
        }
    }

    private func prepareIssueReport(canSendMail: Bool) {
        let attachmentURL = ensureAuditLogFileExistsIfPossible()
        let draft = IssueReportDraft(
            id: UUID(),
            recipient: Self.reportIssueRecipientEmail,
            subject: Self.reportIssueSubject,
            body: buildIssueReportBody(),
            attachmentURL: attachmentURL,
            attachmentFileName: "audit-log.jsonl",
            attachmentMimeType: "text/plain"
        )

        if canSendMail {
            state.presentation = .issueReport(draft)
            return
        }

        state.presentation = .mailUnavailable
    }

    private func ensureAuditLogFileExistsIfPossible(fileManager: FileManager = .default) -> URL? {
        guard let fileURL = auditLogger.auditLogFileURL else { return nil }

        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directoryURL.path) {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            }
            if !fileManager.fileExists(atPath: fileURL.path) {
                fileManager.createFile(atPath: fileURL.path, contents: nil)
            }
            return fileURL
        } catch {
            state.errorMessage = error.localizedDescription
            return nil
        }
    }

    private func buildIssueReportBody(
        date: Date = Date(),
        bundle: Bundle = .main,
        processInfo: ProcessInfo = .processInfo,
        currentDevice: UIDevice = .current
    ) -> String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        let osVersion = processInfo.operatingSystemVersionString
        let deviceModel = currentDevice.model
        let timestamp = ISO8601DateFormatter().string(from: date)

        return [
            "Issue Summary:",
            "",
            "Steps to Reproduce:",
            "",
            "Expected Result:",
            "",
            "Actual Result:",
            "",
            "--- Environment ---",
            "App Version: \(version) (\(build))",
            "OS: \(osVersion)",
            "Device: \(deviceModel)",
            "Timestamp: \(timestamp)"
        ].joined(separator: "\n")
    }
}
