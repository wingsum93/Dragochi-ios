//
//  AppRouterTests.swift
//  DragochiTests
//
//  Created by Codex on 29/5/2026.
//

import Testing
@testable import Dragochi

struct AppRouterTests {
    @Test
    @MainActor
    func init_defaultsToHomeTab() {
        let router = AppRouter()

        #expect(router.selectedTab == .home)
    }

    @Test
    @MainActor
    func route_updatesSelectedTab() {
        let router = AppRouter()

        router.route(to: .stats)

        #expect(router.selectedTab == .stats)
    }

    @Test
    @MainActor
    func convenienceMethods_routeToExpectedTabs() {
        let router = AppRouter(selectedTab: .settings)

        router.showHome()
        #expect(router.selectedTab == .home)

        router.showHistory()
        #expect(router.selectedTab == .history)

        router.showStats()
        #expect(router.selectedTab == .stats)

        router.showSettings()
        #expect(router.selectedTab == .settings)
    }
}
