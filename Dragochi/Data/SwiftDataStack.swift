//
//  SwiftDataStack.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import SwiftData

enum SwiftDataStack {
    static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema([
            GameRecord.self,
            FriendRecord.self,
            SessionRecord.self,
            SessionFriendRecord.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeInMemoryContainer() throws -> ModelContainer {
        try makeContainer(inMemory: true)
    }
}

