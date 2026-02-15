//
//  SwiftDataEnabledGameSelectionRepository.swift
//  Dragochi
//
//  Created by Codex on 15/2/2026.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataEnabledGameSelectionRepository: EnabledGameSelectionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchEnabledRemoteIDs() throws -> Set<String> {
        let descriptor = FetchDescriptor<EnabledGameSelectionRecord>()
        let records = try modelContext.fetch(descriptor)
        return Set(records.map(\.remoteID))
    }

    func enable(remoteID: String) throws {
        let trimmed = remoteID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if try fetchRecord(remoteID: trimmed) != nil { return }
        modelContext.insert(EnabledGameSelectionRecord(remoteID: trimmed))
        try modelContext.save()
    }

    func disable(remoteID: String) throws {
        guard let record = try fetchRecord(remoteID: remoteID) else { return }
        modelContext.delete(record)
        try modelContext.save()
    }

    func removeMissing(remoteIDs: Set<String>) throws {
        let descriptor = FetchDescriptor<EnabledGameSelectionRecord>()
        let records = try modelContext.fetch(descriptor)
        for record in records where !remoteIDs.contains(record.remoteID) {
            modelContext.delete(record)
        }
        try modelContext.save()
    }

    private func fetchRecord(remoteID: String) throws -> EnabledGameSelectionRecord? {
        let descriptor = FetchDescriptor<EnabledGameSelectionRecord>(
            predicate: #Predicate { $0.remoteID == remoteID }
        )
        return try modelContext.fetch(descriptor).first
    }
}
