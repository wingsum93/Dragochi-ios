//
//  AppRouter.swift
//  Dragochi
//
//  Created by Codex on 29/5/2026.
//

import Combine
import Foundation

enum AppTab: Hashable {
    case home
    case history
    case stats
    case settings
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab

    init(selectedTab: AppTab = .home) {
        self.selectedTab = selectedTab
    }

    func route(to tab: AppTab) {
        selectedTab = tab
    }

    func showHome() {
        route(to: .home)
    }

    func showHistory() {
        route(to: .history)
    }

    func showStats() {
        route(to: .stats)
    }

    func showSettings() {
        route(to: .settings)
    }
}
