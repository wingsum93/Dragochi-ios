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
    private static let uiTestFriendsJSONKey = "DRAGOCHI_UI_TEST_FRIENDS_JSON"

    private enum Tab: Hashable {
        case home
        case history
        case stats
        case settings
    }

    @State private var isShowingGameSettings = false
    @State private var isShowingFriendSettings = false
    @State private var selectedTab: Tab = .home

    @StateObject private var mainStore: MainViewModel
    @StateObject private var historyStore: HistoryViewModel
    @StateObject private var statsStore: StatisticViewModel
    @StateObject private var settingsStore: SettingsViewModel

    private let container: AppDIContainer
    private let isUITesting: Bool

    init(container: ModelContainer) {
        let appContainer = AppDIContainer(modelContainer: container)
        let processInfo = ProcessInfo.processInfo

        self.container = appContainer
        self.isUITesting = processInfo.arguments.contains("-ui-testing")
        if self.isUITesting {
            Self.seedUITestFriendsIfNeeded(container: appContainer, processInfo: processInfo)
        }
        _mainStore = StateObject(wrappedValue: appContainer.makeMainViewModel())
        _historyStore = StateObject(wrappedValue: appContainer.makeHistoryViewModel())
        _statsStore = StateObject(wrappedValue: appContainer.makeStatisticViewModel())
        _settingsStore = StateObject(wrappedValue: appContainer.makeSettingsViewModel())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MainView(
                viewModel: mainStore,
                container: container,
                onOpenGameSettings: { isShowingGameSettings = true },
                onOpenFriendSettings: { isShowingFriendSettings = true }
            )
                .tabItem {
                    Label("title_tab_home", systemImage: "gamecontroller")
                        .accessibilityIdentifier("tab.home.button")
                }
                .tag(Tab.home)

            HistoryView(viewModel: historyStore)
                .tabItem {
                    Label("title_tab_history", systemImage: "clock.arrow.circlepath")
                        .accessibilityIdentifier("tab.history.button")
                }
                .tag(Tab.history)

            StatisticView(viewModel: statsStore)
                .tabItem {
                    Label("title_tab_stats", systemImage: "chart.bar")
                        .accessibilityIdentifier("tab.stats.button")
                }
                .tag(Tab.stats)

            SettingsView(
                viewModel: settingsStore,
                container: container,
                onOpenGameSettings: { isShowingGameSettings = true },
                onOpenFriendSettings: { isShowingFriendSettings = true }
            )
                .tabItem {
                    Label("title_tab_settings", systemImage: "gearshape")
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
        .fullScreenCover(isPresented: $isShowingGameSettings) {
            GameSettingsFullPage(
                viewModel: container.makeGameSettingsViewModel(
                    onClose: { isShowingGameSettings = false }
                )
            )
        }
        .fullScreenCover(isPresented: $isShowingFriendSettings) {
            FriendSettingsFullPage(
                viewModel: container.makeFriendSettingsViewModel(
                    onClose: { isShowingFriendSettings = false }
                )
            )
        }
    }

    private static func seedUITestFriendsIfNeeded(container: AppDIContainer, processInfo: ProcessInfo) {
        guard let fixtureJSON = processInfo.environment[Self.uiTestFriendsJSONKey] else { return }
        guard let data = fixtureJSON.data(using: .utf8) else { return }

        do {
            let fixtures = try JSONDecoder().decode([UITestFriendFixture].self, from: data)

            // Make each launch deterministic for UI tests by replacing all friends with fixtures.
            let existingFriends = try container.friendRepository.fetchAll()
            for friend in existingFriends {
                try container.friendRepository.delete(id: friend.id)
            }

            for fixture in fixtures {
                let resolvedName = fixture.resolvedName
                guard !resolvedName.isEmpty else { continue }

                _ = try container.friendRepository.create(
                    name: resolvedName,
                    handle: nil,
                    avatarAssetName: fixture.resolvedAvatarAssetName,
                    isActive: true
                )
            }
        } catch {
            assertionFailure("Failed to seed UI test friends: \(error)")
        }
    }
}
