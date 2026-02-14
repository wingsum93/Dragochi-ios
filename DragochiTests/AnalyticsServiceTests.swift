//
//  AnalyticsServiceTests.swift
//  DragochiTests
//
//  Created by Codex on 15/2/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Dragochi

struct AnalyticsServiceTests {
    @Test
    func swiftDataAnalyticsService_computesMonthlyAggregatesAndMoM() async throws {
        try await MainActor.run {
            let container = try SwiftDataStack.makeInMemoryContainer()
            let dependencies = AppDependencies(modelContext: ModelContext(container))

            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

            func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
                let components = DateComponents(
                    calendar: calendar,
                    timeZone: calendar.timeZone,
                    year: year,
                    month: month,
                    day: day,
                    hour: hour,
                    minute: minute
                )
                return calendar.date(from: components) ?? .distantPast
            }

            let gameA = try dependencies.gameRepository.create(name: "Apex Legends", imageAssetName: "apex")
            let gameB = try dependencies.gameRepository.create(name: "LOL", imageAssetName: "lol")

            _ = try dependencies.sessionRepository.create(
                startAt: date(2025, 1, 10, 10, 0),
                endAt: date(2025, 1, 10, 11, 0),
                platform: .pc,
                gameID: gameA.id,
                durationSeconds: nil,
                note: nil,
                friendIDs: []
            )

            _ = try dependencies.sessionRepository.create(
                startAt: date(2025, 2, 10, 10, 0),
                endAt: date(2025, 2, 10, 10, 40),
                platform: .mobile,
                gameID: gameB.id,
                durationSeconds: nil,
                note: nil,
                friendIDs: []
            )

            _ = try dependencies.sessionRepository.create(
                startAt: date(2025, 3, 1, 10, 0),
                endAt: date(2025, 3, 1, 11, 0),
                platform: .pc,
                gameID: gameA.id,
                durationSeconds: 3_600,
                note: nil,
                friendIDs: []
            )

            _ = try dependencies.sessionRepository.create(
                startAt: date(2025, 3, 2, 12, 0),
                endAt: date(2025, 3, 2, 12, 30),
                platform: .mobile,
                gameID: gameB.id,
                durationSeconds: nil,
                note: nil,
                friendIDs: []
            )

            _ = try dependencies.sessionRepository.create(
                startAt: date(2025, 3, 3, 14, 0),
                endAt: date(2025, 3, 3, 14, 20),
                platform: .pc,
                gameID: gameA.id,
                durationSeconds: nil,
                note: nil,
                friendIDs: []
            )

            _ = try dependencies.sessionRepository.create(
                startAt: date(2025, 3, 4, 15, 0),
                endAt: date(2025, 3, 4, 15, 10),
                platform: .console,
                gameID: nil,
                durationSeconds: 600,
                note: nil,
                friendIDs: []
            )

            let service = SwiftDataAnalyticsService(
                sessionRepository: dependencies.sessionRepository,
                calendar: calendar
            )

            let marchMonthStart = calendar.date(from: DateComponents(year: 2025, month: 3, day: 1)) ?? .distantPast
            let marchReport = try service.monthlyReport(for: marchMonthStart)

            #expect(marchReport.monthStart == marchMonthStart)
            #expect(marchReport.totalDurationSeconds == 7_200)

            #expect(marchReport.byPlatform.count == 3)
            #expect(marchReport.byPlatform[0] == PlatformBreakdown(platform: .pc, durationSeconds: 4_800))
            #expect(marchReport.byPlatform[1] == PlatformBreakdown(platform: .mobile, durationSeconds: 1_800))
            #expect(marchReport.byPlatform[2] == PlatformBreakdown(platform: .console, durationSeconds: 600))

            #expect(marchReport.byGame.count == 3)
            #expect(marchReport.byGame[0] == GameBreakdown(gameID: gameA.id, durationSeconds: 4_800))
            #expect(marchReport.byGame[1] == GameBreakdown(gameID: gameB.id, durationSeconds: 1_800))
            #expect(marchReport.byGame[2] == GameBreakdown(gameID: nil, durationSeconds: 600))

            #expect(marchReport.mom?.previousMonthTotalDurationSeconds == 2_400)
            #expect(marchReport.mom?.deltaSeconds == 4_800)
            #expect(marchReport.mom?.percentageChange == 200)
            #expect(marchReport.trendLast6Months.count == 6)
            #expect(marchReport.trendLast6Months.last?.monthStart == marchMonthStart)
            #expect(marchReport.trendLast6Months.last?.totalDurationSeconds == 7_200)

            let januaryMonthStart = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1)) ?? .distantPast
            let januaryReport = try service.monthlyReport(for: januaryMonthStart)
            #expect(januaryReport.totalDurationSeconds == 3_600)
            #expect(januaryReport.mom?.previousMonthTotalDurationSeconds == 0)
            #expect(januaryReport.mom?.percentageChange == nil)
        }
    }
}
