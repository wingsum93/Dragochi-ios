//
//  StubAnalyticsService.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

@MainActor
final class StubAnalyticsService: AnalyticsService {
    func monthlyReport(for monthStart: Date) throws -> MonthlyReport {
        let totalSeconds = 42 * 3600 + 15 * 60
        let byGame = [
            GameBreakdown(gameID: nil, durationSeconds: 6 * 3600 + 10 * 60)
        ]
        let byPlatform = [
            PlatformBreakdown(platform: .pc, durationSeconds: 24 * 3600 + 20 * 60),
            PlatformBreakdown(platform: .mobile, durationSeconds: 10 * 3600 + 15 * 60),
            PlatformBreakdown(platform: .console, durationSeconds: 7 * 3600 + 40 * 60)
        ]
        let mom = MoMComparison(
            previousMonthTotalDurationSeconds: 38 * 3600,
            deltaSeconds: totalSeconds - 38 * 3600,
            percentageChange: 11.2
        )
        let trend = (0..<6).map { offset -> MonthlyTrendPoint in
            let date = Calendar.current.date(byAdding: .month, value: -offset, to: monthStart) ?? monthStart
            let value = totalSeconds - offset * 3600
            return MonthlyTrendPoint(monthStart: date, totalDurationSeconds: max(0, value))
        }.reversed()

        return MonthlyReport(
            monthStart: monthStart,
            totalDurationSeconds: totalSeconds,
            byGame: byGame,
            byPlatform: byPlatform,
            mom: mom,
            trendLast6Months: Array(trend),
            mostFrequentTeammates: [],
            rareTeammates90Days: []
        )
    }
}

