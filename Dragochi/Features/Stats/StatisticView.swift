//
//  StatisticView.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI

struct StatisticView: View {
    @ObservedObject var viewModel: StatisticViewModel
    @Environment(\.locale) private var locale

    var body: some View {
        ZStack {
            DragonTheme.current.color(.bgBase).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.lg)) {
                    header
                    monthSelector
                    reportSummary
                    platformBreakdown
                    gameBreakdown
                }
                .padding(.horizontal, DragonTheme.current.spacing(.lg))
                .padding(.top, DragonTheme.current.spacing(.lg))
                .padding(.bottom, DragonTheme.current.spacing(.xl))
            }
        }
        .accessibilityIdentifier("screen.stats")
        .onAppear { viewModel.send(.onAppear) }
    }

    private var header: some View {
        Text("title_stats")
            .font(DragonTheme.current.font(.titleSection))
            .foregroundStyle(DragonTheme.current.color(.textPrimary))
    }

    private var monthSelector: some View {
        HStack {
            Button {
                viewModel.send(.previousMonth)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.state.canGoPreviousMonth)
            .opacity(viewModel.state.canGoPreviousMonth ? 1 : 0.4)
            .accessibilityIdentifier("action.statsPreviousMonth")

            Spacer()

            Text(monthTitle(viewModel.state.monthStart))
                .font(DragonTheme.current.font(.titleSection))
                .foregroundStyle(DragonTheme.current.color(.textPrimary))

            Spacer()

            Button {
                viewModel.send(.nextMonth)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.state.canGoNextMonth)
            .opacity(viewModel.state.canGoNextMonth ? 1 : 0.4)
            .accessibilityIdentifier("action.statsNextMonth")
        }
        .foregroundStyle(DragonTheme.current.color(.accentPrimary))
    }

    private var reportSummary: some View {
        VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
            Text("title_total_playtime")
                .font(DragonTheme.current.font(.labelSmall))
                .foregroundStyle(DragonTheme.current.color(.textTertiary))

            Text(formatDuration(viewModel.state.report?.totalDurationSeconds ?? 0))
                .font(DragonTheme.current.font(.displayTimer))
                .foregroundStyle(DragonTheme.current.color(.accentPrimary))

            if let mom = viewModel.state.report?.mom {
                Text(L10n.format("text_mom_format", locale: locale, formatPercentage(mom.percentageChange)))
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
            Text("title_platform_breakdown")
                .font(DragonTheme.current.font(.labelSmall))
                .foregroundStyle(DragonTheme.current.color(.textTertiary))

            ForEach(viewModel.state.report?.byPlatform ?? [], id: \.platform) { item in
                HStack {
                    Text(L10n.string(item.platform.titleKey, locale: locale))
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

    private var gameBreakdown: some View {
        VStack(alignment: .leading, spacing: DragonTheme.current.spacing(.sm)) {
            Text("title_game_breakdown")
                .font(DragonTheme.current.font(.labelSmall))
                .foregroundStyle(DragonTheme.current.color(.textTertiary))

            ForEach(Array((viewModel.state.report?.byGame ?? []).enumerated()), id: \.offset) { _, item in
                HStack {
                    Text((viewModel.gameName(for: item.gameID) ?? L10n.string("text_unknown_game", locale: locale)).uppercased())
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
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: date)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return L10n.format("text_duration_hours_minutes_short", locale: locale, hours, minutes)
    }

    private func formatPercentage(_ value: Double?) -> String {
        guard let value else { return L10n.string("text_na", locale: locale) }
        return String(format: "%.1f%%", value)
    }
}
