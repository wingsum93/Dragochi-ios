//
//  FileAuditLogger.swift
//  Dragochi
//
//  Created by Codex on 23/3/2026.
//

import Foundation

@MainActor
final class FileAuditLogger: AuditLogging {
    let fileURL: URL
    var auditLogFileURL: URL? { fileURL }

    private let fileManager: FileManager
    private let encoder: JSONEncoder

    init(
        fileURL: URL,
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func log(action: AuditAction, outcome: AuditOutcome, metadata: [String: String]) {
        let record = AuditRecord(
            id: UUID(),
            timestamp: Date(),
            action: action,
            outcome: outcome,
            metadata: metadata
        )

        do {
            try append(record: record)
        } catch {
            print("Audit logger failed to persist record: \(error)")
        }
    }

    private func append(record: AuditRecord) throws {
        try ensureParentDirectoryAndFile()

        var line = try encoder.encode(record)
        line.append(0x0A)

        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }
        handle.seekToEndOfFile()
        try handle.write(contentsOf: line)
    }

    private func ensureParentDirectoryAndFile() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: nil)
        }
    }
}
