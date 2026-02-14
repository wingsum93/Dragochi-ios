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
        ZStack(alignment: .bottomTrailing) {
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
                .padding(.bottom, 120)
            }

            Button {
                store.send(.openAddSession)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 54, height: 54)
                    .background(DragonTheme.current.color(.accentPrimary))
                    .clipShape(Circle())
                    .shadow(color: DragonTheme.current.color(.accentPrimary).opacity(0.4), radius: 10)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("action.openAddSession")
            .padding(.trailing, DragonTheme.current.spacing(.lg))
            .padding(.bottom, DragonTheme.current.spacing(.xl))
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
        HStack {
            Circle()
                .fill(DragonTheme.current.color(.surfaceCard))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "gamecontroller")
                        .foregroundStyle(DragonTheme.current.color(.textTertiary))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(row.gameTitle)
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))
                Text(row.subtitle)
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

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return "\(hours)H \(minutes)M"
    }
}
