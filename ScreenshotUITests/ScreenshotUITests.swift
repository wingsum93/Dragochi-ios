//
//  ScreenshotUITests.swift
//  ScreenshotUITests
//
//  Created by eric ho on 11/2/2026.
//

import XCTest

final class ScreenshotUITests: XCTestCase {
    private static let uiTestFriendsJSONKey = "DRAGOCHI_UI_TEST_FRIENDS_JSON"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testScreenshotHomeIdleNoResume() throws {
        let app = launchAppForScreenshots()

        waitForElementToAppear(element(in: app, id: "action.startTracking"))
        XCTAssertFalse(element(in: app, id: "card.resumeLastSetup").exists)
        attachScreenshot(from: app, named: "home_idle_no_resume.png")
    }

    @MainActor
    func testScreenshotHomeIdleResume() throws {
        let app = launchAppForScreenshots()

        startTrackingFromHome(in: app)
        stopTracking(in: app)

        let resumeCard = element(in: app, id: "card.resumeLastSetup")
        waitForElementToAppear(resumeCard)
        attachScreenshot(from: app, named: "home_idle_resume.png")
    }

    @MainActor
    func testScreenshotHomeRunning() throws {
        let app = launchAppForScreenshots()

        startTrackingFromHome(in: app)

        let stopButton = element(in: app, id: "action.stopTracking")
        let pauseResumeButton = element(in: app, id: "action.pauseResumeTracking")
        waitForElementToAppear(stopButton)
        waitForElementToAppear(pauseResumeButton)
        waitForElementToAppear(app.staticTexts["KEEP GOING"])
        XCTAssertFalse(element(in: app, id: "card.resumeLastSetup").exists)
        attachScreenshot(from: app, named: "home_running.png")
    }

    @MainActor
    func testScreenshotHistory() throws {
        let app = launchAppForScreenshots()

        tapTab("tab.history.button", in: app)
        let totalPlaytimeLabel = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "TOTAL PLAYTIME:")).firstMatch
        waitForElementToAppear(totalPlaytimeLabel)
        attachScreenshot(from: app, named: "history.png")
    }

    @MainActor
    func testScreenshotStats() throws {
        let app = launchAppForScreenshots()

        tapTab("tab.stats.button", in: app)
        let totalPlaytime = app.staticTexts["Total Playtime"]
        let platformBreakdown = app.staticTexts["Platform Breakdown"]
        let gameBreakdown = app.staticTexts["Game Breakdown"]
        let previousMonthButton = app.buttons["action.statsPreviousMonth"]
        let nextMonthButton = app.buttons["action.statsNextMonth"]

        waitForElementToAppear(totalPlaytime)
        waitForElementToAppear(platformBreakdown)
        waitForElementToAppear(gameBreakdown)
        waitForElementToAppear(previousMonthButton)
        waitForElementToAppear(nextMonthButton)

        XCTAssertGreaterThan(gameBreakdown.frame.minY, platformBreakdown.frame.maxY)
        XCTAssertFalse(previousMonthButton.isEnabled)
        XCTAssertFalse(nextMonthButton.isEnabled)
        attachScreenshot(from: app, named: "stats.png")
    }

    @MainActor
    func testScreenshotSettings() throws {
        let app = launchAppForScreenshots()

        tapTab("tab.settings.button", in: app)
        waitForElementToAppear(app.staticTexts["iCloud Sync"])
        attachScreenshot(from: app, named: "settings.png")
    }

    @MainActor
    func testSettingsReportIssueShowsMailUnavailableFallbackActions() throws {
        let app = launchAppForScreenshots()

        tapTab("tab.settings.button", in: app)
        waitForElementToAppear(app.staticTexts["iCloud Sync"])

        let reportIssueButton = element(in: app, id: "action.reportIssueToDeveloper")
        scrollToElementIfNeeded(reportIssueButton, in: app)
        waitForElementToAppear(reportIssueButton)
        reportIssueButton.tap()

        waitForElementToAppear(app.staticTexts["Mail Not Available"])
        let copyEmailButton = app.buttons["Copy Developer Email"]
        waitForElementToAppear(copyEmailButton)
        waitForElementToAppear(app.buttons["Open Mail App"])

        // Verify fallback action is callable.
        copyEmailButton.tap()
    }

    @MainActor
    func testSettingsFriendImportSheetShowsAppleAndGoogleActions() throws {
        let app = launchAppForScreenshots()

        tapTab("tab.settings.button", in: app)
        waitForElementToAppear(app.staticTexts["iCloud Sync"])

        let importFriendsButton = element(in: app, id: "action.openFriendImportOptionsFromSettings")
        scrollToElementIfNeeded(importFriendsButton, in: app)
        waitForElementToAppear(importFriendsButton)
        importFriendsButton.tap()

        waitForElementToAppear(element(in: app, id: "sheet.friendImportOptions"))
        waitForElementToAppear(element(in: app, id: "action.importFromAppleInSheet"))
        waitForElementToAppear(element(in: app, id: "action.importFromGoogleInSheet"))
    }

    @MainActor
    func testSettingsGoogleImportShowsComingSoonAlert() throws {
        let app = launchAppForScreenshots()

        tapTab("tab.settings.button", in: app)
        waitForElementToAppear(app.staticTexts["iCloud Sync"])

        let importFriendsButton = element(in: app, id: "action.openFriendImportOptionsFromSettings")
        scrollToElementIfNeeded(importFriendsButton, in: app)
        waitForElementToAppear(importFriendsButton)
        importFriendsButton.tap()

        let importGoogleButton = element(in: app, id: "action.importFromGoogleInSheet")
        waitForElementToAppear(importGoogleButton)
        importGoogleButton.tap()

        waitForElementToAppear(app.staticTexts["Google import is coming soon."])
    }

    @MainActor
    func testSettingsAppleImportOpensFullScreenImportPage() throws {
        let app = launchAppForScreenshots()

        tapTab("tab.settings.button", in: app)
        waitForElementToAppear(app.staticTexts["iCloud Sync"])

        let importFriendsButton = element(in: app, id: "action.openFriendImportOptionsFromSettings")
        scrollToElementIfNeeded(importFriendsButton, in: app)
        waitForElementToAppear(importFriendsButton)
        importFriendsButton.tap()

        let importAppleButton = element(in: app, id: "action.importFromAppleInSheet")
        waitForElementToAppear(importAppleButton)
        importAppleButton.tap()

        waitForElementToAppear(element(in: app, id: "screen.appleFriendImport"))
        waitForElementToAppear(element(in: app, id: "action.importFromAppleInImportScreen"))
    }

    @MainActor
    func testLanguageSectionOpensPerAppLanguageSettings() throws {
        let app = launchAppForScreenshots()

        tapTab("tab.settings.button", in: app)
        waitForElementToAppear(app.staticTexts["iCloud Sync"])

        let openPerAppLanguageButton = app.buttons["Per-App Language"]
        scrollToElementIfNeeded(openPerAppLanguageButton, in: app)
        waitForElementToAppear(openPerAppLanguageButton)
        XCTAssertTrue(openPerAppLanguageButton.isHittable)
        openPerAppLanguageButton.tap()

        let preferencesApp = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        XCTAssertTrue(
            preferencesApp.wait(for: .runningForeground, timeout: 10),
            "Expected Settings app to open from Per-App Language action."
        )
        XCTAssertTrue(
            waitForDragochiContext(from: app, in: preferencesApp, timeout: 10),
            "Expected Settings app to show Dragochi-specific context instead of generic General settings."
        )
    }

    @MainActor
    func testScreenshotSessionSetup() throws {
        let app = launchAppForScreenshots()
        openPreStartSetupFromHome(in: app)

        let notesSection = element(in: app, id: "section.sessionNotes")
        waitForElementToAppear(notesSection)
        let startTrackingButton = element(in: app, id: "action.saveSession")
        waitForElementToAppear(startTrackingButton)

        XCTAssertFalse(element(in: app, id: "action.stopTracking").exists)
        XCTAssertLessThan(notesSection.frame.maxY, startTrackingButton.frame.minY)
        attachScreenshot(from: app, named: "add-session.png")
    }

    @MainActor
    func testToolbarAddButtonOpensManualRecordSheet() throws {
        let app = launchAppForScreenshots()

        let addButton = element(in: app, id: "action.openAddSession")
        waitForElementToAppear(addButton)
        addButton.tap()

        waitForElementToAppear(element(in: app, id: "screen.addSession"))
        waitForElementToAppear(element(in: app, id: "action.saveSession"))
        XCTAssertFalse(element(in: app, id: "action.stopTracking").exists)
    }


    @MainActor
    func testOpenFriendSettingsFromAddSession_NoFriend() throws {
        let app = launchAppForScreenshots(friendFixtureJSON: "[]")
        openFriendSettingsFromAddSession(in: app)

        waitForElementToAppear(app.staticTexts["No friends yet"])
        XCTAssertEqual(friendRowCount(in: app), 0)
        attachScreenshot(from: app, named: "friend-settings-no-friend.png")
    }

    @MainActor
    func testOpenFriendSettingsFromAddSession_OneFriend() throws {
        let fixtureJSON = """
        [{"name":"Ava","avatarAssetName":"F1"}]
        """
        let app = launchAppForScreenshots(friendFixtureJSON: fixtureJSON)
        openFriendSettingsFromAddSession(in: app)

        waitForElementToAppear(app.staticTexts["Ava"])
        XCTAssertEqual(friendRowCount(in: app), 1)
        attachScreenshot(from: app, named: "friend-settings-one-friend.png")
    }

    @MainActor
    func testOpenFriendSettingsFromAddSession_ManyFriends() throws {
        let fixtureJSON = """
        [
          {"name":"Ava","avatarAssetName":"F1"},
          {"name":"Kai","avatarAssetName":"M2"},
          {"name":"Noah","avatarAssetName":"M3"},
          {"name":"Luna","avatarAssetName":"F4"},
          {"name":"Jude","avatarAssetName":"M5"}
        ]
        """
        let app = launchAppForScreenshots(friendFixtureJSON: fixtureJSON)
        openFriendSettingsFromAddSession(in: app)

        waitForElementToAppear(app.staticTexts["Ava"])
        waitForElementToAppear(app.staticTexts["Kai"])
        XCTAssertEqual(friendRowCount(in: app), 5)
        attachScreenshot(from: app, named: "friend-settings-many-friends.png")
    }

    @discardableResult
    private func launchAppForScreenshots(friendFixtureJSON: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_US",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryM",
            "-ui-testing"
        ]
        app.launchEnvironment["TZ"] = "UTC"
        app.launchEnvironment["UIViewAnimationDurationMultiplier"] = "0"
        if let friendFixtureJSON {
            app.launchEnvironment[Self.uiTestFriendsJSONKey] = friendFixtureJSON
        }
        app.launch()
        return app
    }

    private func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval = 10) {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)

        if result != .completed {
            XCTFail("Timed out waiting for element to appear: \(element)")
        }
    }

    private func attachScreenshot(from app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func element(in app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func tapTab(_ id: String, in app: XCUIApplication) {
        let tab = element(in: app, id: id)
        waitForElementToAppear(tab)
        tab.tap()
    }

    private func scrollToElementIfNeeded(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) {
        guard !element.exists else { return }

        for _ in 0..<maxSwipes {
            app.swipeUp()
            if element.exists {
                return
            }
        }
    }

    private func ensureTrackingIsIdle(in app: XCUIApplication) {
        let startButton = element(in: app, id: "action.startTracking")
        if startButton.waitForExistence(timeout: 20) {
            return
        }

        let stopButton = element(in: app, id: "action.stopTracking")
        if stopButton.waitForExistence(timeout: 5) {
            stopButton.tap()
            waitForElementToAppear(startButton)
            return
        }

        XCTFail("Unable to reach home idle state: neither start nor stop tracking button appeared.")
    }

    private func openPreStartSetupFromHome(in app: XCUIApplication) {
        ensureTrackingIsIdle(in: app)
        let startButton = element(in: app, id: "action.startTracking")
        waitForElementToAppear(startButton)
        startButton.tap()

        waitForElementToAppear(element(in: app, id: "screen.addSession"))
        waitForElementToAppear(element(in: app, id: "hero.addSessionTitle"))
        waitForElementToAppear(element(in: app, id: "section.gamePlayed"))
    }

    private func startTrackingFromHome(in app: XCUIApplication) {
        openPreStartSetupFromHome(in: app)

        let selectableGameButtons = app.descendants(matching: .button).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "action.selectGame.")
        )
        let firstSelectableGameButton = selectableGameButtons.firstMatch
        waitForElementToAppear(firstSelectableGameButton)
        firstSelectableGameButton.tap()

        let saveButton = element(in: app, id: "action.saveSession")
        waitForElementToAppear(saveButton)
        saveButton.tap()

        waitForElementToAppear(element(in: app, id: "action.stopTracking"))
    }

    private func stopTracking(in app: XCUIApplication) {
        let stopButton = element(in: app, id: "action.stopTracking")
        waitForElementToAppear(stopButton)
        stopButton.tap()
        waitForElementToAppear(element(in: app, id: "action.startTracking"))
    }

    private func openFriendSettingsFromAddSession(in app: XCUIApplication) {
        if !element(in: app, id: "screen.addSession").exists {
            tapTab("tab.home.button", in: app)

            switch waitForAddSessionEntryState(in: app) {
            case .addSession:
                break
            case .startTracking:
                element(in: app, id: "action.startTracking").tap()
                waitForElementToAppear(element(in: app, id: "screen.addSession"))
            case .stopTracking:
                element(in: app, id: "action.stopTracking").tap()
                waitForElementToAppear(element(in: app, id: "action.startTracking"))
                element(in: app, id: "action.startTracking").tap()
                waitForElementToAppear(element(in: app, id: "screen.addSession"))
            case nil:
                XCTFail("Unable to open Add Session: no known entry state appeared.")
                return
            }
        }

        let addTeammateButton = element(in: app, id: "action.addTeammate")
        waitForElementToAppear(addTeammateButton)
        addTeammateButton.tap()

        waitForElementToAppear(element(in: app, id: "screen.friendSettings"))
    }

    private func friendRowCount(in app: XCUIApplication) -> Int {
        let rowQuery = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "row.friend.")
        )
        let uniqueRowIDs = Set(rowQuery.allElementsBoundByIndex.map(\.identifier))
        return uniqueRowIDs.count
    }

    private enum AddSessionEntryState {
        case addSession
        case startTracking
        case stopTracking
    }

    private func waitForAddSessionEntryState(in app: XCUIApplication, timeout: TimeInterval = 20) -> AddSessionEntryState? {
        let addTeammate = element(in: app, id: "action.addTeammate")
        let start = element(in: app, id: "action.startTracking")
        let stop = element(in: app, id: "action.stopTracking")
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if addTeammate.exists {
                return .addSession
            }
            if start.exists {
                return .startTracking
            }
            if stop.exists {
                return .stopTracking
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        return nil
    }

    private func waitForDragochiContext(from app: XCUIApplication, in settingsApp: XCUIApplication, timeout: TimeInterval) -> Bool {
        let dragochiLabelPredicate = NSPredicate(format: "label CONTAINS[c] %@", "Dragochi")
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let hasAppLabelContext = settingsApp.descendants(matching: .any).matching(dragochiLabelPredicate).count > 0
            let appMovedToBackground = app.state == .runningBackground || app.state == .runningBackgroundSuspended
            let settingsLoadedContent = settingsApp.tables.firstMatch.exists
                || settingsApp.collectionViews.firstMatch.exists
                || settingsApp.scrollViews.firstMatch.exists
            let hasAppContext = hasAppLabelContext || (appMovedToBackground && settingsLoadedContent)
            if hasAppContext {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        return false
    }
}
