//
//  StatsStore.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import Combine

@MainActor
final class StatsStore: ObservableObject {
    struct State: Equatable {
        var monthStart: Date
        var report: MonthlyReport?
        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case onAppear
        case previousMonth
        case nextMonth
        case refresh
    }

    @Published private(set) var state: State

    private let analyticsService: AnalyticsService

    init(dependencies: AppDependencies) {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        self.state = State(monthStart: monthStart, report: nil)
        self.analyticsService = dependencies.analyticsService
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear, .refresh:
            loadReport()
        case .previousMonth:
            shiftMonth(by: -1)
        case .nextMonth:
            shiftMonth(by: 1)
        }
    }

    private func shiftMonth(by offset: Int) {
        let calendar = Calendar.current
        if let updated = calendar.date(byAdding: .month, value: offset, to: state.monthStart) {
            state.monthStart = updated
            loadReport()
        }
    }

    private func loadReport() {
        state.isLoading = true
        defer { state.isLoading = false }
        do {
            state.report = try analyticsService.monthlyReport(for: state.monthStart)
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }
}
