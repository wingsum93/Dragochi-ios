//
//  BackupService.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

@MainActor
protocol BackupService {
    func export() throws -> BackupPayload
    func `import`(_ payload: BackupPayload) throws
}

