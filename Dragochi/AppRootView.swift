//
//  AppRootView.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import SwiftUI
import SwiftData

@MainActor
struct AppRootView: View {
    @State private var addSessionDraft: AddSessionDraft?

    @StateObject private var mainStore: MainStore
    @StateObject private var historyStore: HistoryStore
    @StateObject private var statsStore: StatsStore
    @StateObject private var settingsStore: SettingsStore

    private let dependencies: AppDependencies

    init(container: ModelContainer) {
        let modelContext = ModelContext(container)
        let dependencies = AppDependencies(modelContext: modelContext)

        self.dependencies = dependencies
        _mainStore = StateObject(wrappedValue: MainStore(dependencies: dependencies))
        _historyStore = StateObject(wrappedValue: HistoryStore(dependencies: dependencies))
        _statsStore = StateObject(wrappedValue: StatsStore(dependencies: dependencies))
        _settingsStore = StateObject(wrappedValue: SettingsStore(dependencies: dependencies))
    }

    var body: some View {
        TabView {
            MainView(store: mainStore)
                .tabItem { Label("Home", systemImage: "house") }
                .accessibilityIdentifier("tab.home")

            HistoryView(store: historyStore)
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .accessibilityIdentifier("tab.history")

            StatsView(store: statsStore)
                .tabItem { Label("Stats", systemImage: "chart.bar") }
                .accessibilityIdentifier("tab.stats")

            SettingsView(store: settingsStore)
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .accessibilityIdentifier("tab.settings")
        }
        .tint(DragonTheme.current.color(.tabTintShine))
        
        .sheet(item: $addSessionDraft) { draft in
            AddSessionView(
                store: AddSessionStore(
                    dependencies: dependencies,
                    draft: draft,
                    onSetupConfirmed: draft.mode == .preStartSetup ? { setup in
                        mainStore.send(.preStartSetupConfirmed(setup))
                    } : nil,
                    onClose: { addSessionDraft = nil }
                )
            )
        }
        .onChange(of: mainStore.state.pendingAddSessionDraft) { _, draft in
            guard let draft else { return }
            addSessionDraft = draft
            mainStore.send(.clearPendingDraft)
        }
    }
}
