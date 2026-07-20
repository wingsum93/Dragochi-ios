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

    @State private var isShowingGameSettings = false
    @State private var isShowingFriendSettings = false
    @State private var addSessionDraft: AddSessionDraft?
    @StateObject private var appRouter = AppRouter()

    @StateObject private var mainViewModel: MainViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @StateObject private var statsViewModel: StatisticViewModel
    @StateObject private var settingsViewModel: SettingViewModel

    private let makeAddSessionViewModel: (
        AddSessionDraft,
        ((SessionSetupInput) -> Void)?,
        @escaping () -> Void,
        @escaping () -> Void,
        @escaping () -> Void
    ) -> AddSessionViewModel
    private let makeGameSettingViewModel: (@escaping () -> Void) -> GameSettingViewModel
    private let makeFriendSettingViewModel: (@escaping () -> Void) -> FriendSettingViewModel
    private let makeAppleFriendImportViewModel: (@escaping () -> Void) -> AppleFriendImportViewModel
    private let isUITesting: Bool

    init(container: ModelContainer) {
        let appContainer = AppDIContainer(modelContainer: container)
        let processInfo = ProcessInfo.processInfo

        self.isUITesting = processInfo.arguments.contains("-ui-testing")
        if self.isUITesting {
            Self.seedUITestFriendsIfNeeded(friendRepository: appContainer.friendRepository, processInfo: processInfo)
        }
        _mainViewModel = StateObject(wrappedValue: appContainer.makeMainViewModel())
        _historyViewModel = StateObject(wrappedValue: appContainer.makeHistoryViewModel())
        _statsViewModel = StateObject(wrappedValue: appContainer.makeStatisticViewModel())
        _settingsViewModel = StateObject(wrappedValue: appContainer.makeSettingViewModel())
        self.makeAddSessionViewModel = { draft, onSetupConfirmed, onOpenGameSettings, onOpenFriendSettings, onClose in
            appContainer.makeAddSessionViewModel(
                draft: draft,
                onSetupConfirmed: onSetupConfirmed,
                onOpenGameSettings: onOpenGameSettings,
                onOpenFriendSettings: onOpenFriendSettings,
                onClose: onClose
            )
        }
        self.makeGameSettingViewModel = { onClose in
            appContainer.makeGameSettingViewModel(onClose: onClose)
        }
        self.makeFriendSettingViewModel = { onClose in
            appContainer.makeFriendSettingViewModel(onClose: onClose)
        }
        self.makeAppleFriendImportViewModel = { onClose in
            appContainer.makeAppleFriendImportViewModel(onClose: onClose)
        }
    }

    var body: some View {
        TabView(selection: $appRouter.selectedTab) {
            MainView(
                viewModel: mainViewModel,
                makeAddSessionViewModel: makeAddSessionViewModel,
                onOpenGameSettings: { isShowingGameSettings = true },
                onOpenFriendSettings: { isShowingFriendSettings = true }
            )
                .tabItem {
                    Label("title_tab_home", systemImage: "gamecontroller")
                }
                .tag(AppTab.home)

            HistoryView(viewModel: historyViewModel)
                .tabItem {
                    Label("title_tab_history", systemImage: "clock.arrow.circlepath")
                }
                .tag(AppTab.history)

            StatisticView(viewModel: statsViewModel)
                .tabItem {
                    Label("title_tab_stats", systemImage: "chart.bar")
                }
                .tag(AppTab.stats)

            SettingView(
                viewModel: settingsViewModel,
                makeAppleFriendImportViewModel: makeAppleFriendImportViewModel,
                onOpenGameSettings: { isShowingGameSettings = true },
                onOpenFriendSettings: { isShowingFriendSettings = true }
            )
                .tabItem {
                    Label("title_tab_settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .toolbar(.hidden, for: .tabBar)
        .tint(DragonTheme.current.color(.tabTintShine))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppToolbar(
                selectedTab: $appRouter.selectedTab,
                onAddTapped: showManualAddSession
            )
        }
        .onAppear {
            if isUITesting {
                appRouter.route(to: .home)
            }
        }
        .sheet(item: $addSessionDraft) { draft in
            AddSessionSheet(
                viewModel: makeAddSessionViewModel(
                    draft,
                    nil,
                    {
                        closeAddSessionSheet(refreshData: false)
                        isShowingGameSettings = true
                    },
                    {
                        closeAddSessionSheet(refreshData: false)
                        isShowingFriendSettings = true
                    },
                    { closeAddSessionSheet(refreshData: true) }
                )
            )
        }
        .fullScreenCover(isPresented: $isShowingGameSettings) {
            GameSettingsFullPage(
                viewModel: makeGameSettingViewModel(
                    { isShowingGameSettings = false }
                )
            )
        }
        .fullScreenCover(isPresented: $isShowingFriendSettings) {
            FriendSettingsFullPage(
                viewModel: makeFriendSettingViewModel(
                    { isShowingFriendSettings = false }
                )
            )
        }
    }

    private func showManualAddSession() {
        let draftDate = Date()
        addSessionDraft = AddSessionDraft(
            id: UUID(),
            mode: .manualEntry,
            sessionID: nil,
            startAt: draftDate,
            endAt: draftDate,
            selectedGameID: nil,
            selectedPlatform: .pc,
            selectedFriendIDs: [],
            note: ""
        )
    }

    private func closeAddSessionSheet(refreshData: Bool) {
        addSessionDraft = nil

        guard refreshData else { return }
        mainViewModel.send(.onAppear)
        historyViewModel.send(.onAppear)
        statsViewModel.send(.onAppear)
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
