//
//  SwiftDataAnalyticsService.swift
//  Dragochi
//
//  Created by Codex on 15/2/2026.
//

import Foundation

@MainActor
final class SwiftDataAnalyticsService: AnalyticsService {
    private let sessionRepository: SessionRepository
    private let calendar: Calendar

    init(sessionRepository: SessionRepository, calendar: Calendar = .current) {
        self.sessionRepository = sessionRepository
        self.calendar = calendar
    }

    func monthlyReport(for monthStart: Date) throws -> MonthlyReport {
        let targetMonthStart = startOfMonth(monthStart)
        let sessions = try sessionRepository.fetchEnded(between: .distantPast, and: Date())
        let monthlyTotals = aggregateMonthlyTotals(from: sessions)

        let monthSessions = sessions.filter { session in
            guard let endAt = session.endAt else { return false }
            return startOfMonth(endAt) == targetMonthStart
        }

        let totalDurationSeconds = monthSessions.reduce(0) { total, session in
            total + resolvedDuration(for: session)
        }

        var platformDurationMap: [Platform: Int] = [:]
        var gameDurationMap: [UUID?: Int] = [:]
        for session in monthSessions {
            let duration = resolvedDuration(for: session)
            platformDurationMap[session.platform, default: 0] += duration
            gameDurationMap[session.gameID, default: 0] += duration
        }

        let byPlatform = platformDurationMap
            .map { PlatformBreakdown(platform: $0.key, durationSeconds: $0.value) }
            .sorted { lhs, rhs in
                if lhs.durationSeconds != rhs.durationSeconds {
                    return lhs.durationSeconds > rhs.durationSeconds
                }
                return lhs.platform.rawValue < rhs.platform.rawValue
            }

        let byGame = gameDurationMap
            .map { GameBreakdown(gameID: $0.key, durationSeconds: $0.value) }
            .sorted { lhs, rhs in
                if lhs.durationSeconds != rhs.durationSeconds {
                    return lhs.durationSeconds > rhs.durationSeconds
                }

                switch (lhs.gameID, rhs.gameID) {
                case let (left?, right?):
                    return left.uuidString < right.uuidString
                case (nil, nil):
                    return false
                case (nil, _):
                    return false
                case (_, nil):
                    return true
                }
            }

        let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: targetMonthStart) ?? targetMonthStart
        let previousMonthTotal = monthlyTotals[previousMonthStart] ?? 0
        let delta = totalDurationSeconds - previousMonthTotal
        let percentageChange: Double? = previousMonthTotal > 0
            ? (Double(delta) / Double(previousMonthTotal)) * 100
            : nil
        let mom = MoMComparison(
            previousMonthTotalDurationSeconds: previousMonthTotal,
            deltaSeconds: delta,
            percentageChange: percentageChange
        )

        var trendLast6Months: [MonthlyTrendPoint] = []
        for offset in stride(from: 5, through: 0, by: -1) {
            let month = calendar.date(byAdding: .month, value: -offset, to: targetMonthStart) ?? targetMonthStart
            trendLast6Months.append(
                MonthlyTrendPoint(
                    monthStart: month,
                    totalDurationSeconds: monthlyTotals[month] ?? 0
                )
            )
        }

        return MonthlyReport(
            monthStart: targetMonthStart,
            totalDurationSeconds: totalDurationSeconds,
            byGame: byGame,
            byPlatform: byPlatform,
            mom: mom,
            trendLast6Months: trendLast6Months,
            mostFrequentTeammates: [],
            rareTeammates90Days: []
        )
    }

    private func aggregateMonthlyTotals(from sessions: [SessionEntity]) -> [Date: Int] {
        var totals: [Date: Int] = [:]
        for session in sessions {
            guard let endAt = session.endAt else { continue }
            let month = startOfMonth(endAt)
            totals[month, default: 0] += resolvedDuration(for: session)
        }
        return totals
    }

    private func startOfMonth(_ date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? date
    }

    private func resolvedDuration(for session: SessionEntity) -> Int {
        if let durationSeconds = session.durationSeconds {
            return max(0, durationSeconds)
        }
        guard let endAt = session.endAt else { return 0 }
        return max(0, Int(endAt.timeIntervalSince(session.startAt)))
    }
}
