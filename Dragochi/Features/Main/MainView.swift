//
//  MainView.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI
import Combine

struct MainView: View {
    @ObservedObject var store: MainStore
    @SceneStorage("home.trackingSnapshotData") private var trackingSnapshotData: Data?
    @State private var isResumeLastSetupEnabled = true
    @Environment(\.locale) private var locale

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            DragonTheme.current.color(.bgBase).ignoresSafeArea()

            VStack(spacing: DragonTheme.current.spacing(.lg)) {
                header
                timerSection
                sessionDetailSection
                Spacer()
            }
            .padding(.horizontal, DragonTheme.current.spacing(.lg))
            .padding(.top, DragonTheme.current.spacing(.lg))

            controlSection
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, DragonTheme.current.spacing(.lg))
        }
        .overlay(alignment: .bottom) {
            resumeLastSetupSection
                .padding(.horizontal, DragonTheme.current.spacing(.lg))
                .padding(.bottom, DragonTheme.current.spacing(.lg))
        }
        .onAppear {
            store.send(.onAppear)
            store.send(.restoreTrackingSnapshot(trackingSnapshotData))
        }
        .onReceive(timer) { _ in
            store.send(.tick)
        }
        .onChange(of: store.state.trackingSnapshotData) { _, data in
            trackingSnapshotData = data
        }
        .onReceive(NotificationCenter.default.publisher(for: .friendsDidChange)) { _ in
            store.send(.onAppear)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("title_home_quick_track")
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))
                    .accessibilityIdentifier("screen.home")
                Text("text_home_productivity_mode")
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
            }

            Spacer()
        }
    }

    private var timerSection: some View {
        VStack(spacing: DragonTheme.current.spacing(.sm)) {
            Text(formatDuration(store.state.elapsedSeconds))
                .font(DragonTheme.current.font(.displayTimer))
                .foregroundStyle(DragonTheme.current.color(.textPrimary))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(statusText)
                .font(DragonTheme.current.font(.labelSmall))
                .foregroundStyle(statusColor)
                .tracking(2)
        }
        .padding(.top, DragonTheme.current.spacing(.lg))
    }

    private var sessionDetailSection: some View {
        VStack(spacing: DragonTheme.current.spacing(.sm)) {
            if let startAt = store.state.trackingStartAt {
                Text(L10n.format("text_home_started_at_format", locale: locale, formatTime(startAt)))
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
                    .tracking(1)
            }

            if let setup = store.state.activeSetup {
                HStack(spacing: DragonTheme.current.spacing(.sm)) {
                    chip(title: selectedGameTitle(setup.selectedGameID), icon: "gamecontroller")
                    chip(title: L10n.string(setup.selectedPlatform.titleKey, locale: locale), icon: "desktopcomputer")
                    chip(title: L10n.format("text_home_person_count_format", locale: locale, setup.selectedFriendIDs.count), icon: "person.2")
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var controlSection: some View {
        if store.state.trackingStatus == .idle {
            startButton
        } else {
            VStack(spacing: DragonTheme.current.spacing(.md)) {
                stopButton
                pauseResumeButton
            }
        }
    }

    @ViewBuilder
    private var resumeLastSetupSection: some View {
        if shouldShowResumeLastSetup, let model = resumeLastSetupModel {
            DragonResumeLastSetupCard(
                model: model,
                isResumeEnabled: isResumeLastSetupEnabled,
                onToggleResume: { isEnabled in
                    isResumeLastSetupEnabled = isEnabled
                },
                onTap: {}
            )
        }
    }

    private var startButton: some View {
        Button {
            store.send(.startTapped(resumeLastSetupEnabled: isResumeLastSetupEnabled))
        } label: {
            ZStack {
                Circle()
                    .stroke(DragonTheme.current.color(.accentPrimary), lineWidth: 6)
                    .frame(width: 160, height: 160)
                    .shadow(color: DragonTheme.current.color(.accentPrimary).opacity(0.35), radius: 12)

                Circle()
                    .fill(DragonTheme.current.color(.surfaceCard))
                    .frame(width: 120, height: 120)

                Text("button_start")
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))
                    .accessibilityIdentifier("action.startTracking")
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("action.startTracking")
    }

    private var stopButton: some View {
        Button {
            store.send(.stopTapped)
        } label: {
            ZStack {
                Circle()
                    .stroke(DragonTheme.current.color(.accentPrimary), lineWidth: 6)
                    .frame(width: 180, height: 180)
                    .shadow(color: DragonTheme.current.color(.accentPrimary).opacity(0.35), radius: 12)

                Circle()
                    .fill(DragonTheme.current.color(.surfaceCard))
                    .frame(width: 132, height: 132)

                Text("button_stop")
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))
                    .accessibilityIdentifier("action.stopTracking")
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("action.stopTracking")
    }

    private var pauseResumeButton: some View {
        Button {
            store.send(.pauseResumeTapped)
        } label: {
            Text(
                L10n.string(
                    store.state.trackingStatus == .paused ? "button_resume" : "button_pause",
                    locale: locale
                )
            )
                .font(DragonTheme.current.font(.labelSmall))
                .foregroundStyle(DragonTheme.current.color(.textTertiary))
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.25))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("action.pauseResumeTracking")
    }

    private var statusText: String {
        switch store.state.trackingStatus {
        case .idle:
            return L10n.string("text_home_status_idle", locale: locale)
        case .running:
            return L10n.string("text_home_status_running", locale: locale)
        case .paused:
            return L10n.string("text_home_status_paused", locale: locale)
        }
    }

    private var statusColor: Color {
        switch store.state.trackingStatus {
        case .paused:
            return DragonTheme.current.color(.textTertiary)
        case .idle, .running:
            return DragonTheme.current.color(.accentPrimary)
        }
    }

    private func chip(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .regular))
            Text(title)
                .font(DragonTheme.current.font(.labelSmall))
        }
        .foregroundStyle(DragonTheme.current.color(.textPrimary))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(DragonTheme.current.color(.surfaceCard))
        .clipShape(Capsule())
    }

    private func selectedGameTitle(_ id: UUID) -> String {
        store.state.games.first(where: { $0.id == id })?.name ?? L10n.string("text_unknown_game", locale: locale)
    }

    private var shouldShowResumeLastSetup: Bool {
        store.state.trackingStatus == .idle
            && store.state.currentSessionID == nil
            && store.state.trackingStartAt == nil
            && store.state.activeSetup == nil
    }

    private var resumeLastSetupModel: DragonResumeLastSetupModel? {
        guard let session = store.state.latestEndedSession else { return nil }
        let selectedGame = session.gameID.flatMap { id in
            store.state.games.first(where: { $0.id == id })
        }

        return DragonResumeLastSetupModel(
            id: session.id,
            gameTitle: selectedGame?.name ?? L10n.string("text_unknown_game", locale: locale),
            gameImageAssetName: selectedGame?.imageAssetName,
            platformLabel: L10n.string(session.platform.titleKey, locale: locale),
            teammatesLabel: teammatesLabel(for: session.friendIDs)
        )
    }

    private func teammatesLabel(for friendIDs: [UUID]) -> String {
        let names = friendIDs.compactMap { friendID in
            store.state.friends.first(where: { $0.id == friendID })?.name
        }

        guard !names.isEmpty else {
            return friendIDs.isEmpty
                ? L10n.string("text_teammates_solo", locale: locale)
                : L10n.format("text_teammates_count", locale: locale, friendIDs.count)
        }

        if names.count == 1 {
            return L10n.format("text_teammates_with_one", locale: locale, names[0])
        }
        if names.count == 2 {
            return L10n.format("text_teammates_with_two", locale: locale, names[0], names[1])
        }

        return L10n.format("text_teammates_with_many", locale: locale, names[0], names[1], names.count - 2)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remaining)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
