//
//  MonthlyReport.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

struct MonthlyReport: Codable, Hashable {
    let monthStart: Date
    let totalDurationSeconds: Int
    let byGame: [GameBreakdown]
    let byPlatform: [PlatformBreakdown]
    let mom: MoMComparison?
    let trendLast6Months: [MonthlyTrendPoint]
    let mostFrequentTeammates: [TeammateMetric]
    let rareTeammates90Days: [UUID]
}

struct GameBreakdown: Codable, Hashable {
    let gameID: UUID?
    let durationSeconds: Int
}

struct PlatformBreakdown: Codable, Hashable {
    let platform: Platform
    let durationSeconds: Int
}

struct MoMComparison: Codable, Hashable {
    let previousMonthTotalDurationSeconds: Int
    let deltaSeconds: Int
    let percentageChange: Double?
}

struct MonthlyTrendPoint: Codable, Hashable {
    let monthStart: Date
    let totalDurationSeconds: Int
}

struct TeammateMetric: Codable, Hashable {
    let friendID: UUID
    let sessionCount: Int
    let durationSeconds: Int
}

