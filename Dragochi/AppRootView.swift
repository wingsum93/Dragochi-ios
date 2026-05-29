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

    private let makeAddSessionViewModel: (
        AddSessionDraft,
        ((SessionSetupInput) -> Void)?,
        @escaping () -> Void,
        @escaping () -> Void,
        @escaping () -> Void
    ) -> AddSessionViewModel
    private let makeGameSettingsViewModel: (@escaping () -> Void) -> GameSettingsViewModel
    private let makeFriendSettingsViewModel: (@escaping () -> Void) -> FriendSettingsViewModel
    private let makeAppleFriendImportViewModel: (@escaping () -> Void) -> AppleFriendImportViewModel
    private let isUITesting: Bool

    init(container: ModelContainer) {
        let appContainer = AppDIContainer(modelContainer: container)
        let processInfo = ProcessInfo.processInfo

        self.isUITesting = processInfo.arguments.contains("-ui-testing")
        if self.isUITesting {
            Self.seedUITestFriendsIfNeeded(friendRepository: appContainer.friendRepository, processInfo: processInfo)
        }
        _mainStore = StateObject(wrappedValue: appContainer.makeMainViewModel())
        _historyStore = StateObject(wrappedValue: appContainer.makeHistoryViewModel())
        _statsStore = StateObject(wrappedValue: appContainer.makeStatisticViewModel())
        _settingsStore = StateObject(wrappedValue: appContainer.makeSettingsViewModel())
        self.makeAddSessionViewModel = { draft, onSetupConfirmed, onOpenGameSettings, onOpenFriendSettings, onClose in
            appContainer.makeAddSessionViewModel(
                draft: draft,
                onSetupConfirmed: onSetupConfirmed,
                onOpenGameSettings: onOpenGameSettings,
                onOpenFriendSettings: onOpenFriendSettings,
                onClose: onClose
            )
        }
        self.makeGameSettingsViewModel = { onClose in
            appContainer.makeGameSettingsViewModel(onClose: onClose)
        }
        self.makeFriendSettingsViewModel = { onClose in
            appContainer.makeFriendSettingsViewModel(onClose: onClose)
        }
        self.makeAppleFriendImportViewModel = { onClose in
            appContainer.makeAppleFriendImportViewModel(onClose: onClose)
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MainView(
                viewModel: mainStore,
                makeAddSessionViewModel: makeAddSessionViewModel,
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
                makeAppleFriendImportViewModel: makeAppleFriendImportViewModel,
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
                viewModel: makeGameSettingsViewModel(
                    { isShowingGameSettings = false }
                )
            )
        }
        .fullScreenCover(isPresented: $isShowingFriendSettings) {
            FriendSettingsFullPage(
                viewModel: makeFriendSettingsViewModel(
                    { isShowingFriendSettings = false }
                )
            )
        }
    }

    private static func seedUITestFriendsIfNeeded(friendRepository: FriendRepository, processInfo: ProcessInfo) {
        guard let fixtureJSON = processInfo.environment[Self.uiTestFriendsJSONKey] else { return }
        guard let data = fixtureJSON.data(using: .utf8) else { return }

        do {
            let fixtures = try JSONDecoder().decode([UITestFriendFixture].self, from: data)

            // Make each launch deterministic for UI tests by replacing all friends with fixtures.
            let existingFriends = try friendRepository.fetchAll()
            for friend in existingFriends {
                try friendRepository.delete(id: friend.id)
            }

            for fixture in fixtures {
                let resolvedName = fixture.resolvedName
                guard !resolvedName.isEmpty else { continue }

                _ = try friendRepository.create(
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
