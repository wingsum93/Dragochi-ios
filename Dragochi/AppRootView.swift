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
    private enum Tab: Hashable {
        case home
        case history
        case stats
        case settings
    }

    @State private var addSessionDraft: AddSessionDraft?
    @State private var isShowingGameSettings = false
    @State private var isShowingFriendSettings = false
    @State private var selectedTab: Tab = .home

    @StateObject private var mainStore: MainStore
    @StateObject private var historyStore: HistoryStore
    @StateObject private var statsStore: StatsStore
    @StateObject private var settingsStore: SettingsStore

    private let dependencies: AppDependencies
    private let isUITesting: Bool

    init(container: ModelContainer) {
        let modelContext = ModelContext(container)
        let dependencies = AppDependencies(modelContext: modelContext)

        self.dependencies = dependencies
        self.isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        _mainStore = StateObject(wrappedValue: MainStore(dependencies: dependencies))
        _historyStore = StateObject(wrappedValue: HistoryStore(dependencies: dependencies))
        _statsStore = StateObject(wrappedValue: StatsStore(dependencies: dependencies))
        _settingsStore = StateObject(wrappedValue: SettingsStore(dependencies: dependencies))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MainView(store: mainStore)
                .tabItem {
                    Label("Home", systemImage: "gamecontroller")
                        .accessibilityIdentifier("tab.home.button")
                }
                .tag(Tab.home)

            HistoryView(store: historyStore)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                        .accessibilityIdentifier("tab.history.button")
                }
                .tag(Tab.history)

            StatsView(store: statsStore)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                        .accessibilityIdentifier("tab.stats.button")
                }
                .tag(Tab.stats)

            SettingsView(
                store: settingsStore,
                onOpenGameSettings: { isShowingGameSettings = true },
                onOpenFriendSettings: { isShowingFriendSettings = true }
            )
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                        .accessibilityIdentifier("tab.settings.button")
                }
                .tag(Tab.settings)
        }
        .tint(DragonTheme.current.color(.tabTintShine))
        .onAppear {
            if isUITesting {
                selectedTab = .home
            }
        }
        
        .sheet(item: $addSessionDraft) { draft in
            AddSessionView(
                store: AddSessionStore(
                    dependencies: dependencies,
                    draft: draft,
                    onSetupConfirmed: draft.mode == .preStartSetup ? { setup in
                        mainStore.send(.preStartSetupConfirmed(setup))
                    } : nil,
                    onOpenGameSettings: {
                        addSessionDraft = nil
                        isShowingGameSettings = true
                    },
                    onOpenFriendSettings: {
                        isShowingFriendSettings = true
                    },
                    onClose: { addSessionDraft = nil }
                )
            )
        }
        .fullScreenCover(isPresented: $isShowingGameSettings) {
            GameSettingsView(
                store: GameSettingsStore(
                    dependencies: dependencies,
                    onClose: { isShowingGameSettings = false }
                )
            )
        }
        .fullScreenCover(isPresented: $isShowingFriendSettings) {
            FriendSettingsView(
                store: FriendSettingsStore(
                    dependencies: dependencies,
                    onClose: { isShowingFriendSettings = false }
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
