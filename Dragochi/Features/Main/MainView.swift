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
        .accessibilityIdentifier("screen.home")
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
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Quick Track")
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))
                Text("PRODUCTIVITY MODE")
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
                Text("STARTED \(formatTime(startAt))")
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
                    .tracking(1)
            }

            if let setup = store.state.activeSetup {
                HStack(spacing: DragonTheme.current.spacing(.sm)) {
                    chip(title: selectedGameTitle(setup.selectedGameID), icon: "gamecontroller")
                    chip(title: setup.selectedPlatform.rawValue.uppercased(), icon: "desktopcomputer")
                    chip(title: "\(setup.selectedFriendIDs.count) PERSON", icon: "person.2")
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
        if store.state.trackingStatus == .idle, let model = resumeLastSetupModel {
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
            store.send(.startTapped)
        } label: {
            ZStack {
                Circle()
                    .stroke(DragonTheme.current.color(.accentPrimary), lineWidth: 6)
                    .frame(width: 160, height: 160)
                    .shadow(color: DragonTheme.current.color(.accentPrimary).opacity(0.35), radius: 12)

                Circle()
                    .fill(DragonTheme.current.color(.surfaceCard))
                    .frame(width: 120, height: 120)

                Text("START")
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))
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

                Text("STOP")
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("action.stopTracking")
    }

    private var pauseResumeButton: some View {
        Button {
            store.send(.pauseResumeTapped)
        } label: {
            Text(store.state.trackingStatus == .paused ? "RESUME" : "PAUSE")
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
            return "READY TO GRIND"
        case .running:
            return "KEEP GOING"
        case .paused:
            return "PAUSED"
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
        store.state.games.first(where: { $0.id == id })?.name ?? "Unknown Game"
    }

    private var resumeLastSetupModel: DragonResumeLastSetupModel? {
        guard let session = store.state.latestEndedSession else { return nil }
        let selectedGame = session.gameID.flatMap { id in
            store.state.games.first(where: { $0.id == id })
        }

        return DragonResumeLastSetupModel(
            id: session.id,
            gameTitle: selectedGame?.name ?? "Unknown Game",
            gameImageAssetName: selectedGame?.imageAssetName,
            platformLabel: session.platform.rawValue.uppercased(),
            teammatesLabel: teammatesLabel(for: session.friendIDs)
        )
    }

    private func teammatesLabel(for friendIDs: [UUID]) -> String {
        let names = friendIDs.compactMap { friendID in
            store.state.friends.first(where: { $0.id == friendID })?.name
        }

        guard !names.isEmpty else {
            return friendIDs.isEmpty ? "Solo" : "\(friendIDs.count) teammates"
        }

        if names.count == 1 {
            return "w/ \(names[0])"
        }
        if names.count == 2 {
            return "w/ \(names[0]) & \(names[1])"
        }

        return "w/ \(names[0]), \(names[1]) +\(names.count - 2)"
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remaining)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
