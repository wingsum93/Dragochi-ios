//
//  AuditLoggerTests.swift
//  DragochiTests
//
//  Created by Codex on 23/3/2026.
//

import Foundation
import Testing
@testable import Dragochi

@MainActor
private final class AuditLoggerWithoutFileURL: AuditLogging {
    func log(action: AuditAction, outcome: AuditOutcome, metadata: [String: String]) {
        _ = action
        _ = outcome
        _ = metadata
    }
}

struct AuditLoggerTests {
    @Test
    func fileAuditLogger_createsDirectoryAndFileOnFirstLog() async throws {
        try await MainActor.run {
            let fileManager = FileManager.default
            let rootDirectory = fileManager.temporaryDirectory
                .appendingPathComponent("dragochi-audit-tests-\(UUID().uuidString)", isDirectory: true)
            let fileURL = rootDirectory
                .appendingPathComponent("nested", isDirectory: true)
                .appendingPathComponent("audit-log.jsonl")

            let logger = FileAuditLogger(fileURL: fileURL, fileManager: fileManager)
            logger.log(
                action: .settingsExported,
                outcome: .success,
                metadata: ["sessions_count": "0"]
            )

            #expect(fileManager.fileExists(atPath: fileURL.path))
            let records = try decodeAuditRecords(fileURL: fileURL)
            #expect(records.count == 1)
            #expect(records.first?.action == .settingsExported)
            #expect(records.first?.outcome == .success)
        }
    }

    @Test
    func fileAuditLogger_persistsMoreThanTwentyRecords() async throws {
        try await MainActor.run {
            let fileManager = FileManager.default
            let fileURL = fileManager.temporaryDirectory
                .appendingPathComponent("dragochi-audit-tests-\(UUID().uuidString)", isDirectory: true)
                .appendingPathComponent("audit-log.jsonl")

            let logger = FileAuditLogger(fileURL: fileURL, fileManager: fileManager)
            for index in 0..<25 {
                logger.log(
                    action: .addSessionManualSaved,
                    outcome: index.isMultiple(of: 2) ? .success : .failure,
                    metadata: ["index": String(index)]
                )
            }

            let records = try decodeAuditRecords(fileURL: fileURL)
            #expect(records.count == 25)
            #expect(records.first?.metadata["index"] == "0")
            #expect(records.last?.metadata["index"] == "24")
            #expect(records.contains(where: { $0.outcome == .success }))
            #expect(records.contains(where: { $0.outcome == .failure }))
        }
    }

    @Test
    func fileAuditLogger_exposesAuditLogFileURL() async throws {
        try await MainActor.run {
            let fileManager = FileManager.default
            let fileURL = fileManager.temporaryDirectory
                .appendingPathComponent("dragochi-audit-tests-\(UUID().uuidString)", isDirectory: true)
                .appendingPathComponent("audit-log.jsonl")
            let logger = FileAuditLogger(fileURL: fileURL, fileManager: fileManager)

            #expect(logger.auditLogFileURL == fileURL)
        }
    }

    @Test
    func auditLoggingDefaultFileURLIsNilForNonFileLogger() async throws {
        try await MainActor.run {
            let logger = AuditLoggerWithoutFileURL()
            #expect(logger.auditLogFileURL == nil)
        }
    }

    private func decodeAuditRecords(fileURL: URL) throws -> [AuditRecord] {
        let raw = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = raw.split(separator: "\n").map(String.init)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try lines.map { line in
            try decoder.decode(AuditRecord.self, from: Data(line.utf8))
        }
    }
}
