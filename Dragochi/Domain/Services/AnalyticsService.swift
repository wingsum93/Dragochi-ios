//
//  AnalyticsService.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

@MainActor
protocol AnalyticsService {
    func monthlyReport(for monthStart: Date) throws -> MonthlyReport
}

