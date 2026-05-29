//
//  HistoryViewModel.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    enum HistoryFilter: CaseIterable {
        case allTime
        case thisWeek
        case lastMonth
    }

    struct HistoryRow: Identifiable, Equatable {
        let id: UUID
        let gameTitle: String
        let platform: Platform
        let durationSeconds: Int
        let endAt: Date
        let friendInfoText: String
    }

    struct HistorySection: Identifiable, Equatable {
        let id: Date
        let day: Date
        let rows: [HistoryRow]
    }

    struct State: Equatable {
        var filter: HistoryFilter = .allTime
        var sections: [HistorySection] = []
        var totalPlaytimeSeconds: Int = 0
        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case onAppear
        case selectFilter(HistoryFilter)
        case refresh
    }

    @Published private(set) var state = State()

    private let sessionRepository: SessionRepository
    private let gameRepository: GameRepository
    private let friendRepository: FriendRepository

    init(dependencies: AppDependencies) {
        self.sessionRepository = dependencies.sessionRepository
        self.gameRepository = dependencies.gameRepository
        self.friendRepository = dependencies.friendRepository
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear, .refresh:
            loadSessions()
        case .selectFilter(let filter):
            state.filter = filter
            loadSessions()
        }
    }

    private func loadSessions() {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            let games = try gameRepository.fetchAll()
            let friends = try friendRepository.fetchAll()
            let gameMap = Dictionary(uniqueKeysWithValues: games.map { ($0.id, $0.name) })
            let friendNameMap = Dictionary(uniqueKeysWithValues: friends.map { ($0.id, $0.name) })
            let interval = dateInterval(for: state.filter)
            let sessions = try sessionRepository.fetchEnded(between: interval.start, and: interval.end)
            let locale = Locale.current

            let rows = sessions.compactMap { session -> HistoryRow? in
                guard let endAt = session.endAt else { return nil }
                let title = session.gameID.flatMap { gameMap[$0] } ?? ""
                return HistoryRow(
                    id: session.id,
                    gameTitle: title,
                    platform: session.platform,
                    durationSeconds: session.durationSeconds ?? 0,
                    endAt: endAt,
                    friendInfoText: friendInfoText(
                        for: session.friendIDs,
                        friendNameMap: friendNameMap,
                        locale: locale
                    )
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
                day: day,
                rows: grouped[day] ?? []
            )
        }
    }

    private func friendInfoText(for friendIDs: [UUID], friendNameMap: [UUID: String], locale: Locale) -> String {
        guard !friendIDs.isEmpty else {
            return L10n.string("text_teammates_solo", locale: locale)
        }

        if friendIDs.count >= 3 {
            return L10n.format("text_history_friend_count_format", locale: locale, friendIDs.count)
        }

        let names = friendIDs.compactMap { friendNameMap[$0] }
        guard names.count == friendIDs.count else {
            return L10n.format("text_history_friend_count_format", locale: locale, friendIDs.count)
        }

        return names.joined(separator: ", ")
    }
}
