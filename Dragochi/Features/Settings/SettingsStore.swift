//
//  SettingsStore.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    struct State: Equatable {
        var isICloudSyncOn: Bool = false
        var lastBackupDate: Date?
        var isExporting: Bool = false
        var isImporting: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case onAppear
        case toggleICloud(Bool)
        case exportTapped
        case importTapped
    }

    @Published private(set) var state = State()

    private let backupService: BackupService

    init(dependencies: AppDependencies) {
        self.backupService = dependencies.backupService
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
        }
    }

    private func exportBackup() {
        state.isExporting = true
        defer { state.isExporting = false }
        do {
            let payload = try backupService.export()
            state.lastBackupDate = payload.exportedAt
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func importBackup() {
        state.isImporting = true
        defer { state.isImporting = false }
        do {
            let payload = BackupPayload(games: [], friends: [], sessions: [])
            try backupService.import(payload)
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }
}
