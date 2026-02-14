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

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            DragonTheme.current.color(.bgBase).ignoresSafeArea()

            VStack(spacing: DragonTheme.current.spacing(.lg)) {
                header
                selectorChips
                timerSection
                resumeCard
                Spacer()
                startStopButton
            }
            .padding(.horizontal, DragonTheme.current.spacing(.lg))
            .padding(.top, DragonTheme.current.spacing(.lg))
        }
        .accessibilityIdentifier("screen.home")
        .onAppear { store.send(.onAppear) }
        .onReceive(timer) { _ in
            store.send(.tick)
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

            Button {
                store.send(.openAddSession)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DragonTheme.current.color(.accentPrimary))
                    .frame(width: 36, height: 36)
                    .background(DragonTheme.current.color(.surfaceCard))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("action.openAddSession")
        }
    }

    private var selectorChips: some View {
        HStack(spacing: DragonTheme.current.spacing(.sm)) {
            if let game = selectedGameTitle {
                chip(title: game, icon: "gamecontroller")
            }
            chip(title: store.state.selectedPlatform.rawValue.uppercased(), icon: "desktopcomputer")
            Button {
                store.send(.openAddSession)
            } label: {
                Image(systemName: "plus")
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
                    .frame(width: 32, height: 32)
                    .background(DragonTheme.current.color(.surfaceCard))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("action.openAddSession")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timerSection: some View {
        VStack(spacing: DragonTheme.current.spacing(.md)) {
            Text(formatDuration(store.state.elapsedSeconds))
                .font(DragonTheme.current.font(.displayTimer))
                .foregroundStyle(DragonTheme.current.color(.textPrimary))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(store.state.isRunning ? "KEEP GOING" : "READY TO GRIND")
                .font(DragonTheme.current.font(.labelSmall))
                .foregroundStyle(DragonTheme.current.color(.accentPrimary))
                .tracking(2)
        }
        .padding(.top, DragonTheme.current.spacing(.lg))
    }

    private var resumeCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("RESUME LAST SETUP")
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
                if let game = selectedGameTitle {
                    Text(game)
                        .font(DragonTheme.current.font(.titleSection))
                        .foregroundStyle(DragonTheme.current.color(.textPrimary))
                }
                Text(store.state.selectedPlatform.rawValue.uppercased())
                    .font(DragonTheme.current.font(.labelSmall))
                    .foregroundStyle(DragonTheme.current.color(.textTertiary))
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { store.state.resumeLastSetup },
                set: { store.send(.toggleResume($0)) }
            ))
            .labelsHidden()
            .tint(DragonTheme.current.color(.accentPrimary))
        }
        .padding(DragonTheme.current.spacing(.md))
        .background(DragonTheme.current.color(.surfaceCard))
        .clipShape(RoundedRectangle(cornerRadius: DragonTheme.current.radius(.card), style: .continuous))
    }

    private var startStopButton: some View {
        Button {
            store.send(.startStopTapped)
        } label: {
            ZStack {
                Circle()
                    .stroke(DragonTheme.current.color(.accentPrimary), lineWidth: 6)
                    .frame(width: 160, height: 160)
                    .shadow(color: DragonTheme.current.color(.accentPrimary).opacity(0.35), radius: 12)

                Circle()
                    .fill(DragonTheme.current.color(.surfaceCard))
                    .frame(width: 120, height: 120)

                Text(store.state.isRunning ? "STOP" : "START")
                    .font(DragonTheme.current.font(.titleSection))
                    .foregroundStyle(DragonTheme.current.color(.textPrimary))
            }
        }
        .buttonStyle(.plain)
        .padding(.bottom, DragonTheme.current.spacing(.xl))
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

    private var selectedGameTitle: String? {
        guard let id = store.state.selectedGameID else { return nil }
        return store.state.games.first { $0.id == id }?.name
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remaining)
    }
}
