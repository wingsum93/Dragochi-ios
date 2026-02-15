//
//  HistoryView.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: HistoryStore

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
            Text("History")
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
                    Text(filter.rawValue)
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
        Text("TOTAL PLAYTIME: \(formatDuration(store.state.totalPlaytimeSeconds))")
            .font(DragonTheme.current.font(.labelSmall))
            .foregroundStyle(DragonTheme.current.color(.accentPrimary))
            .tracking(1)
    }

    private var sections: some View {
        VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.lg)) {
            ForEach(store.state.sections) { section in
                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
                    Text(section.title.uppercased())
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
        HStack(spacing: DragonTheme.current.spacing(.md)) {
            Circle()
                .fill(DragonTheme.current.color(.surfaceCard))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: platformIconName(for: row.platform))
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(row.gameTitle)
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))
                Text(row.platform.rawValue.uppercased())
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(row.durationText)
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.accentPrimary))
                Text(row.timeText)
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
        return "\(hours)H \(minutes)M"
    }
}
