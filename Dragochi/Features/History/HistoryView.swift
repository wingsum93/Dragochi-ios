//
//  HistoryView.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: HistoryStore
    @Environment(\.locale) private var locale

    var body: some View {
        ZStack {
            DragonTheme.current.color(.bgBase).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.lg)) {
                    header
                    filterBar
                    totalPlaytime
                    sections
                }
                .padding(.horizontal, DragonTheme.current.spacing(.lg))
                .padding(.top, DragonTheme.current.spacing(.lg))
                .padding(.bottom, DragonTheme.current.spacing(.xl))
            }
        }
        .accessibilityIdentifier("screen.history")
        .onAppear { store.send(.onAppear) }
    }

    private var header: some View {
        HStack {
            Text("title_history")
                .font(DragonTheme.current.font(.titleSection))
                .foregroundStyle(DragonTheme.current.color(.textPrimary))
            Spacer()
            Image(systemName: "folder")
                .foregroundStyle(DragonTheme.current.color(.accentPrimary))
                .frame(width: 36, height: 36)
                .background(DragonTheme.current.color(.surfaceCard))
                .clipShape(Circle())
        }
    }

    private var filterBar: some View {
        HStack(spacing: DragonTheme.current.spacing(.sm)) {
            ForEach(HistoryStore.HistoryFilter.allCases, id: \.self) { filter in
                Button {
                    store.send(.selectFilter(filter))
                } label: {
                    Text(filterTitle(for: filter))
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(store.state.filter == filter ? .black : DragonTheme.current.color(.textTertiary))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(store.state.filter == filter ? DragonTheme.current.color(.accentPrimary) : DragonTheme.current.color(.surfaceCard))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var totalPlaytime: some View {
        Text(L10n.format("text_history_total_playtime_format", locale: locale, formatDuration(store.state.totalPlaytimeSeconds)))
            .font(DragonTheme.current.font(.labelSmall))
            .foregroundStyle(DragonTheme.current.color(.accentPrimary))
            .tracking(1)
    }

    private var sections: some View {
        VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.lg)) {
            ForEach(store.state.sections) { section in
                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    Text(sectionTitle(for: section.day))
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))
                    ForEach(section.rows) { row in
                        rowCard(row)
                    }
                }
            }
        }
    }

    private func rowCard(_ row: HistoryStore.HistoryRow) -> some View {
        HistoryRowCardView(row: row, locale: locale)
    }

    private func filterTitle(for filter: HistoryStore.HistoryFilter) -> String {
        let key: String
        switch filter {
        case .allTime:
            key = "title_filter_all_time"
        case .thisWeek:
            key = "title_filter_this_week"
        case .lastMonth:
            key = "title_filter_last_month"
        }
        return L10n.string(key, locale: locale)
    }

    private func sectionTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) {
            return L10n.string("title_today", locale: locale)
        }
        if calendar.isDateInYesterday(day) {
            return L10n.string("title_yesterday", locale: locale)
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: day)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return L10n.format("text_duration_hours_minutes_short", locale: locale, hours, minutes)
    }
}

private struct HistoryRowCardView: View {
    let row: HistoryStore.HistoryRow
    let locale: Locale

    var body: some View {
        HStack(spacing: DragonTheme.current.spacing(.md)) {
            Circle()
                .fill(DragonTheme.current.color(.surfaceCard))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: platformIconName(for: row.platform))
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(row.gameTitle.isEmpty ? L10n.string("text_unknown_game", locale: locale) : row.gameTitle)
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))
                Text(L10n.string(row.platform.titleKey, locale: locale))
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
                Text(row.friendInfoText)
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(row.durationSeconds))
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.accentPrimary))
                Text(formatTime(row.endAt))
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
            }
        }
        .padding(DragonTheme.current.spacing(.md))
        .background(DragonTheme.current.color(.surfaceCard))
        .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
    }

    private func platformIconName(for platform: Platform) -> String {
        switch platform {
        case .pc:
            return "desktopcomputer"
        case .console:
            return "gamecontroller"
        case .mobile:
            return "iphone"
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return L10n.format("text_duration_hours_minutes_short", locale: locale, hours, minutes)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct HistoryRowVariantsPreview: View {
    private let previewLocale = Locale(identifier: "en")
    private let rows: [HistoryStore.HistoryRow] = [
        .init(
            id: UUID(),
            gameTitle: "Valorant",
            platform: .pc,
            durationSeconds: 1800,
            endAt: Date(timeIntervalSince1970: 1_700_000_000),
            friendInfoText: "Solo"
        ),
        .init(
            id: UUID(),
            gameTitle: "Apex Legends",
            platform: .console,
            durationSeconds: 2700,
            endAt: Date(timeIntervalSince1970: 1_700_000_600),
            friendInfoText: "Alex"
        ),
        .init(
            id: UUID(),
            gameTitle: "Clash Royale",
            platform: .mobile,
            durationSeconds: 3600,
            endAt: Date(timeIntervalSince1970: 1_700_001_200),
            friendInfoText: "Alex, Ben"
        ),
        .init(
            id: UUID(),
            gameTitle: "League of Legends",
            platform: .pc,
            durationSeconds: 4200,
            endAt: Date(timeIntervalSince1970: 1_700_001_800),
            friendInfoText: "3 friends"
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                ForEach(rows) { row in
                    HistoryRowCardView(row: row, locale: previewLocale)
                }
            }
            .padding(DragonTheme.current.spacing(.lg))
        }
        .background(DragonTheme.current.color(.bgBase))
    }
}

#Preview("History Row Friend Variants") {
    HistoryRowVariantsPreview()
}
