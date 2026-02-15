//
//  EnabledGameSelectionRepository.swift
//  Dragochi
//
//  Created by Codex on 15/2/2026.
//

import Foundation

@MainActor
protocol EnabledGameSelectionRepository {
    func fetchEnabledRemoteIDs() throws -> Set<String>
    func enable(remoteID: String) throws
    func disable(remoteID: String) throws
    func removeMissing(remoteIDs: Set<String>) throws
}
