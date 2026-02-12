//
//  HistoryStore.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import Combine

@MainActor
final class HistoryStore: ObservableObject {
    enum HistoryFilter: String, CaseIterable {
        case allTime = "All Time"
        case thisWeek = "This Week"
        case lastMonth = "Last Month"
    }

    struct HistoryRow: Identifiable, Equatable {
        let id: UUID
        let gameTitle: String
        let subtitle: String
        let durationText: String
        let timeText: String
    }

    struct HistorySection: Identifiable, Equatable {
        let id: Date
        let title: String
        let rows: [HistoryRow]
    }

    struct State: Equatable {
        var filter: HistoryFilter = .allTime
        var sections: [HistorySection] = []
        var totalPlaytimeSeconds: Int = 0
        var isLoading: Bool = false
        var pendingAddSessionDraft: AddSessionDraft?
        var errorMessage: String?
    }

    enum Action {
        case onAppear
        case selectFilter(HistoryFilter)
        case refresh
        case openAddSession
        case clearPendingDraft
    }

    @Published private(set) var state = State()

    private let sessionRepository: SessionRepository
    private let gameRepository: GameRepository

    init(dependencies: AppDependencies) {
        self.sessionRepository = dependencies.sessionRepository
        self.gameRepository = dependencies.gameRepository
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear, .refresh:
            loadSessions()
        case .selectFilter(let filter):
            state.filter = filter
            loadSessions()
        case .openAddSession:
            state.pendingAddSessionDraft = AddSessionDraft(
                id: UUID(),
                sessionID: nil,
                startAt: Date(),
                endAt: Date(),
                selectedGameID: nil,
                selectedPlatform: .pc,
                selectedFriendIDs: [],
                note: ""
            )
        case .clearPendingDraft:
            state.pendingAddSessionDraft = nil
        }
    }

    private func loadSessions() {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            let games = try gameRepository.fetchAll()
            let gameMap = Dictionary(uniqueKeysWithValues: games.map { ($0.id, $0.name) })
            let interval = dateInterval(for: state.filter)
            let sessions = try sessionRepository.fetchEnded(between: interval.start, and: interval.end)

            let rows = sessions.compactMap { session -> HistoryRow? in
                guard let endAt = session.endAt else { return nil }
                let title = session.gameID.flatMap { gameMap[$0] } ?? "Unknown Game"
                let subtitle = session.platform.rawValue.uppercased()
                return HistoryRow(
                    id: session.id,
                    gameTitle: title,
                    subtitle: subtitle,
                    durationText: formatDurationShort(session.durationSeconds ?? 0),
                    timeText: formatTime(endAt)
                )
            }

            state.totalPlaytimeSeconds = sessions.reduce(0) { total, session in
                total + (session.durationSeconds ?? 0)
            }

            state.sections = groupRowsByDay(rows: rows, sessions: sessions)
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private func dateInterval(for filter: HistoryFilter) -> DateInterval {
        let calendar = Calendar.current
        let now = Date()

        switch filter {
        case .allTime:
            return DateInterval(start: .distantPast, end: now)
        case .thisWeek:
            if let interval = calendar.dateInterval(of: .weekOfYear, for: now) {
                return interval
            }
            return DateInterval(start: .distantPast, end: now)
        case .lastMonth:
            guard let thisMonth = calendar.dateInterval(of: .month, for: now),
                  let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonth.start),
                  let lastMonth = calendar.dateInterval(of: .month, for: lastMonthStart) else {
                return DateInterval(start: .distantPast, end: now)
            }
            return lastMonth
        }
    }

    private func groupRowsByDay(rows: [HistoryRow], sessions: [SessionEntity]) -> [HistorySection] {
        let calendar = Calendar.current
        var grouped: [Date: [HistoryRow]] = [:]
        let rowMap = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })

        for session in sessions {
            guard let endAt = session.endAt else { continue }
            guard let row = rowMap[session.id] else { continue }
            let day = calendar.startOfDay(for: endAt)
            grouped[day, default: []].append(row)
        }

        let sortedDays = grouped.keys.sorted(by: >)
        return sortedDays.map { day in
            HistorySection(
                id: day,
                title: sectionTitle(for: day),
                rows: grouped[day] ?? []
            )
        }
    }

    private func sectionTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: day)
    }

    private func formatDurationShort(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
