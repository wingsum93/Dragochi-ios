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
        var availableMonthStarts: [Date] = []
        var canGoPreviousMonth: Bool = false
        var canGoNextMonth: Bool = false
        var report: MonthlyReport?
        var gameNameByID: [UUID: String] = [:]
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
    private let sessionRepository: SessionRepository
    private let gameRepository: GameRepository
    private let calendar = Calendar.current

    init(dependencies: AppDependencies) {
        let now = Date()
        let monthStart = Calendar.current.dateInterval(of: .month, for: now)?.start ?? now
        self.state = State(monthStart: monthStart, report: nil)
        self.analyticsService = dependencies.analyticsService
        self.sessionRepository = dependencies.sessionRepository
        self.gameRepository = dependencies.gameRepository
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear, .refresh:
            refreshAvailableMonthsAndReport()
        case .previousMonth:
            shiftMonth(by: -1)
        case .nextMonth:
            shiftMonth(by: 1)
        }
    }

    private func shiftMonth(by offset: Int) {
        guard !state.availableMonthStarts.isEmpty else {
            updateNavigationAvailability()
            return
        }

        let currentMonth = startOfMonth(state.monthStart)
        guard let currentIndex = state.availableMonthStarts.firstIndex(of: currentMonth) else {
            updateNavigationAvailability()
            return
        }

        let targetIndex = currentIndex + offset
        guard state.availableMonthStarts.indices.contains(targetIndex) else {
            updateNavigationAvailability()
            return
        }

        state.monthStart = state.availableMonthStarts[targetIndex]
        loadReportForCurrentMonth()
        updateNavigationAvailability()
    }

    private func refreshAvailableMonthsAndReport() {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            let endedSessions = try sessionRepository.fetchEnded(between: .distantPast, and: Date())
            state.availableMonthStarts = Array(
                Set(endedSessions.compactMap { session in
                    guard let endAt = session.endAt else { return nil }
                    return startOfMonth(endAt)
                })
            ).sorted()

            state.monthStart = resolveSelectedMonth(
                currentMonthStart: startOfMonth(state.monthStart),
                availableMonthStarts: state.availableMonthStarts
            )

            state.report = try analyticsService.monthlyReport(for: state.monthStart)
            let games = try gameRepository.fetchAll()
            state.gameNameByID = Dictionary(uniqueKeysWithValues: games.map { ($0.id, $0.name) })
            state.errorMessage = nil
            updateNavigationAvailability()
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func loadReportForCurrentMonth() {
        do {
            state.report = try analyticsService.monthlyReport(for: state.monthStart)
            let games = try gameRepository.fetchAll()
            state.gameNameByID = Dictionary(uniqueKeysWithValues: games.map { ($0.id, $0.name) })
            state.errorMessage = nil
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func resolveSelectedMonth(currentMonthStart: Date, availableMonthStarts: [Date]) -> Date {
        if availableMonthStarts.contains(currentMonthStart) {
            return currentMonthStart
        }
        if let latestMonth = availableMonthStarts.last {
            return latestMonth
        }
        return currentMonthStart
    }

    private func updateNavigationAvailability() {
        let currentMonth = startOfMonth(state.monthStart)
        guard let index = state.availableMonthStarts.firstIndex(of: currentMonth) else {
            state.canGoPreviousMonth = false
            state.canGoNextMonth = false
            return
        }
        state.canGoPreviousMonth = index > 0
        state.canGoNextMonth = index < state.availableMonthStarts.count - 1
    }

    private func startOfMonth(_ date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? date
    }

    func gameName(for gameID: UUID?) -> String {
        guard
            let gameID,
            let name = state.gameNameByID[gameID],
            !name.isEmpty
        else {
            return "Unknown Game"
        }
        return name
    }
}
