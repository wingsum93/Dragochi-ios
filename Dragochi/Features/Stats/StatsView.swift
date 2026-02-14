//
//  StatsView.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

struct StatsView: View {
    @ObservedObject var store: StatsStore

    var body: some View {
        ZStack {
            DragonTheme.current.color(.bgBase).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.lg)) {
                    header
                    monthSelector
                    reportSummary
                    platformBreakdown
                }
                .padding(.horizontal, DragonTheme.current.spacing(.lg))
                .padding(.top, DragonTheme.current.spacing(.lg))
                .padding(.bottom, 80)
            }
        }
        .accessibilityIdentifier("screen.stats")
        .onAppear { store.send(.onAppear) }
    }

    private var header: some View {
        Text("Stats")
            .font(DragonTheme.current.font(.titleSection))
            .foregroundStyle(DragonTheme.current.color(.textPrimary))
    }

    private var monthSelector: some View {
        HStack {
            Button {
                store.send(.previousMonth)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Spacer()

            Text(monthTitle(store.state.monthStart))
                .font(DragonTheme.current.font(.titleSection))
                .foregroundStyle(DragonTheme.current.color(.textPrimary))

            Spacer()

            Button {
                store.send(.nextMonth)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(DragonTheme.current.color(.accentPrimary))
    }

    private var reportSummary: some View {
        VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
            Text("Total Playtime")
                .font(DragonTheme.current.font(.labelSmall))
                .foregroundStyle(DragonTheme.current.color(.textTertiary))

            Text(formatDuration(store.state.report?.totalDurationSeconds ?? 0))
                .font(DragonTheme.current.font(.displayTimer))
                .foregroundStyle(DragonTheme.current.color(.accentPrimary))

            if let mom = store.state.report?.mom {
                Text("MoM: \(formatPercentage(mom.percentageChange))")
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textSecondary))
            }
        }
        .padding(DragonTheme.current.spacing(.md))
        .background(DragonTheme.current.color(.surfaceCard))
        .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
    }

    private var platformBreakdown: some View {
        VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
            Text("Platform Breakdown")
                .font(DragonTheme.current.font(.labelSmall))
                .foregroundStyle(DragonTheme.current.color(.textTertiary))

            ForEach(store.state.report?.byPlatform ?? [], id: \.platform) { item in
                HStack {
                    Text(item.platform.rawValue.uppercased())
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(DragonTheme.current.color(.textPrimary))
                    Spacer()
                    Text(formatDuration(item.durationSeconds))
                        .font(DragonTheme.current.font(.labelSmall))
                        .foregroundStyle(DragonTheme.current.color(.accentPrimary))
                }
                .padding(.vertical, 6)
            }
        }
        .padding(DragonTheme.current.spacing(.md))
        .background(DragonTheme.current.color(.surfaceCard))
        .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
    }

    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private func formatPercentage(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        return String(format: "%.1f%%", value)
    }
}
