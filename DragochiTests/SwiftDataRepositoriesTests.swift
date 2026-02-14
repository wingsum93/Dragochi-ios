//
//  SwiftDataRepositoriesTests.swift
//  DragochiTests
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Dragochi

struct SwiftDataRepositoriesTests {
    @Test
    func gameRepository_crud() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let modelContext = ModelContext(container)
            let repository = SwiftDataGameRepository(modelContext: modelContext)

            let created = try repository.create(name: "Valorant", imageAssetName: "volarant")
            #expect(created.name == "Valorant")
            #expect(created.imageAssetName == "volarant")

            let fetched = try repository.fetch(id: created.id)
            #expect(fetched?.id == created.id)
            #expect(fetched?.imageAssetName == "volarant")

            let all = try repository.fetchAll()
            #expect(all.count == 1)

            try repository.delete(id: created.id)
            #expect(try repository.fetchAll().isEmpty)
        }
    }

    @Test
    func friendRepository_crud() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let modelContext = ModelContext(container)
            let repository = SwiftDataFriendRepository(modelContext: modelContext)

            let created = try repository.create(name: "Mason", handle: "@mason")
            #expect(created.name == "Mason")

            let fetched = try repository.fetch(id: created.id)
            #expect(fetched?.handle == "@mason")

            var updated = created
            updated.name = "Mason Updated"
            let upserted = try repository.upsert(updated)
            #expect(upserted.name == "Mason Updated")

            try repository.delete(id: created.id)
            #expect(try repository.fetch(id: created.id) == nil)
        }
    }

    @Test
    func sessionRepository_createUpdateFetchEndedDelete() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let modelContext = ModelContext(container)

            let gameRepository = SwiftDataGameRepository(modelContext: modelContext)
            let friendRepository = SwiftDataFriendRepository(modelContext: modelContext)
            let sessionRepository = SwiftDataSessionRepository(modelContext: modelContext)

            let game = try gameRepository.create(name: "LOL", imageAssetName: "lol")
            let friend1 = try friendRepository.create(name: "Aiden", handle: nil)
            let friend2 = try friendRepository.create(name: "Kai", handle: nil)
            let friend3 = try friendRepository.create(name: "Noah", handle: nil)

            let start1 = Date(timeIntervalSince1970: 1_700_000_000)
            let end1 = start1.addingTimeInterval(60)
            let session1 = try sessionRepository.create(
                startAt: start1,
                endAt: end1,
                platform: .pc,
                gameID: game.id,
                note: "first",
                friendIDs: [friend1.id, friend2.id]
            )

            let fetched1 = try sessionRepository.fetch(id: session1.id)
            #expect(fetched1?.platform == .pc)
            #expect(fetched1?.gameID == game.id)
            #expect(Set(fetched1?.friendIDs ?? []) == Set([friend1.id, friend2.id]))

            var toUpdate = session1
            toUpdate.note = "updated"
            toUpdate.friendIDs = [friend1.id, friend3.id]
            let updated = try sessionRepository.update(toUpdate)
            #expect(updated.note == "updated")
            #expect(Set(updated.friendIDs) == Set([friend1.id, friend3.id]))

            let start2 = start1.addingTimeInterval(120)
            let end2 = start2.addingTimeInterval(180)
            let session2 = try sessionRepository.create(
                startAt: start2,
                endAt: end2,
                platform: .mobile,
                gameID: nil,
                note: "second",
                friendIDs: [friend2.id]
            )

            let ended = try sessionRepository.fetchEnded(
                between: start1.addingTimeInterval(-1),
                and: end2.addingTimeInterval(1)
            )
            #expect(ended.count == 2)
            #expect(ended.first?.id == session2.id)

            try sessionRepository.delete(id: session1.id)
            #expect(try sessionRepository.fetch(id: session1.id) == nil)
        }
    }
}
