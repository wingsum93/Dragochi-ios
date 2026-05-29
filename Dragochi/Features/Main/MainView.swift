//
//  MainView.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI
import Combine

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    let makeAddSessionViewModel: (
        AddSessionDraft,
        ((SessionSetupInput) -> Void)?,
        @escaping () -> Void,
        @escaping () -> Void,
        @escaping () -> Void
    ) -> AddSessionViewModel
    let onOpenGameSettings: () -> Void
    let onOpenFriendSettings: () -> Void
    @SceneStorage("home.trackingSnapshotData") private var trackingSnapshotData: Data?
    @State private var isResumeLastSetupEnabled = true
    @State private var addSessionDraft: AddSessionDraft?
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
            viewModel.send(.onAppear)
            viewModel.send(.restoreTrackingSnapshot(trackingSnapshotData))
        }
        .onReceive(timer) { _ in
            viewModel.send(.tick)
        }
        .onChange(of: viewModel.state.trackingSnapshotData) { _, data in
            trackingSnapshotData = data
        }
        .onChange(of: viewModel.state.pendingAddSessionDraft) { _, draft in
            guard let draft else { return }
            addSessionDraft = draft
            viewModel.send(.clearPendingDraft)
        }
        .onReceive(NotificationCenter.default.publisher(for: .friendsDidChange)) { _ in
            viewModel.send(.onAppear)
        }
        .sheet(item: $addSessionDraft) { draft in
            AddSessionSheet(
                viewModel: makeAddSessionViewModel(
                    draft,
                    draft.mode == .preStartSetup ? { setup in
                        viewModel.send(.preStartSetupConfirmed(setup))
                    } : nil,
                    {
                        addSessionDraft = nil
                        onOpenGameSettings()
                    },
                    {
                        addSessionDraft = nil
                        onOpenFriendSettings()
                    },
                    { addSessionDraft = nil }
                )
            )
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
            Text(formatDuration(viewModel.state.elapsedSeconds))
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
            if let startAt = viewModel.state.trackingStartAt {
                Text(L10n.format("text_home_started_at_format", locale: locale, formatTime(startAt)))
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
                    .tracking(1)
            }

            if let setup = viewModel.state.activeSetup {
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
        if viewModel.state.trackingStatus == .idle {
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
            viewModel.send(.startTapped(resumeLastSetupEnabled: isResumeLastSetupEnabled))
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
            viewModel.send(.stopTapped)
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
            viewModel.send(.pauseResumeTapped)
        } label: {
            Text(
                L10n.string(
                    viewModel.state.trackingStatus == .paused ? "button_resume" : "button_pause",
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
        switch viewModel.state.trackingStatus {
        case .idle:
            return L10n.string("text_home_status_idle", locale: locale)
        case .running:
            return L10n.string("text_home_status_running", locale: locale)
        case .paused:
            return L10n.string("text_home_status_paused", locale: locale)
        }
    }

    private var statusColor: Color {
        switch viewModel.state.trackingStatus {
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
        viewModel.state.games.first(where: { $0.id == id })?.name ?? L10n.string("text_unknown_game", locale: locale)
    }

    private var shouldShowResumeLastSetup: Bool {
        viewModel.state.trackingStatus == .idle
            && viewModel.state.currentSessionID == nil
            && viewModel.state.trackingStartAt == nil
            && viewModel.state.activeSetup == nil
    }

    private var resumeLastSetupModel: DragonResumeLastSetupModel? {
        guard let session = viewModel.state.latestEndedSession else { return nil }
        let selectedGame = session.gameID.flatMap { id in
            viewModel.state.games.first(where: { $0.id == id })
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
            viewModel.state.friends.first(where: { $0.id == friendID })?.name
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
