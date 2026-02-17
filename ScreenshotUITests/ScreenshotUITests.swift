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
    func testScreenshotHome() throws {
        let app = launchAppForScreenshots()

        waitForElementToAppear(app.staticTexts["Quick Track"])
        attachScreenshot(from: app, named: "home.png")
    }

    @MainActor
    func testScreenshotHomeStart() throws {
        let app = launchAppForScreenshots()
        ensureTrackingIsIdle(in: app)

        let startButton = element(in: app, id: "action.startTracking")
        startButton.tap()

        let addSessionScreen = element(in: app, id: "screen.addSession")
        waitForElementToAppear(addSessionScreen)
        waitForElementToAppear(element(in: app, id: "hero.addSessionTitle"))
        waitForElementToAppear(element(in: app, id: "section.gamePlayed"))

        let selectableGameButtons = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "action.selectGame.")
        )
        let firstSelectableGameButton = selectableGameButtons.firstMatch
        waitForElementToAppear(firstSelectableGameButton)
        firstSelectableGameButton.tap()

        let saveButton = element(in: app, id: "action.saveSession")
        waitForElementToAppear(saveButton)
        saveButton.tap()

        let stopButton = element(in: app, id: "action.stopTracking")
        waitForElementToAppear(stopButton)
        attachScreenshot(from: app, named: "home_start.png")

        stopButton.tap()
        waitForElementToAppear(element(in: app, id: "action.startTracking"))
    }

    @MainActor
    func testScreenshotHistory() throws {
        let app = launchAppForScreenshots()

        app.tabBars.buttons["History"].tap()
        let totalPlaytimeLabel = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "TOTAL PLAYTIME:")).firstMatch
        waitForElementToAppear(totalPlaytimeLabel)
        attachScreenshot(from: app, named: "history.png")
    }

    @MainActor
    func testScreenshotStats() throws {
        let app = launchAppForScreenshots()

        app.tabBars.buttons["Stats"].tap()
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

        app.tabBars.buttons["Settings"].tap()
        waitForElementToAppear(app.staticTexts["iCloud Sync"])
        attachScreenshot(from: app, named: "settings.png")
    }

    @MainActor
    func testScreenshotSessionSetup() throws {
        let app = launchAppForScreenshots()
        ensureTrackingIsIdle(in: app)

        let startButton = element(in: app, id: "action.startTracking")
        startButton.tap()

        let addSessionScreen = element(in: app, id: "screen.addSession")
        waitForElementToAppear(addSessionScreen)
        waitForElementToAppear(element(in: app, id: "hero.addSessionTitle"))
        waitForElementToAppear(element(in: app, id: "section.gamePlayed"))
        let notesSection = element(in: app, id: "section.sessionNotes")
        waitForElementToAppear(notesSection)
        let startTrackingButton = element(in: app, id: "action.saveSession")
        waitForElementToAppear(startTrackingButton)

        XCTAssertFalse(element(in: app, id: "action.stopTracking").exists)
        XCTAssertLessThan(notesSection.frame.maxY, startTrackingButton.frame.minY)
        attachScreenshot(from: app, named: "add-session.png")
    }

    @MainActor
    func testOpenFriendSettingsFromSettings() throws {
        let app = launchAppForScreenshots()

        app.tabBars.buttons["Settings"].tap()
        let openFriendSettings = element(in: app, id: "action.openFriendSettingsFromSettings")
        waitForElementToAppear(openFriendSettings)
        openFriendSettings.tap()

        waitForElementToAppear(element(in: app, id: "screen.friendSettings"))
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

    private func openFriendSettingsFromAddSession(in app: XCUIApplication) {
        if !element(in: app, id: "screen.addSession").exists {
            if app.tabBars.buttons["Home"].waitForExistence(timeout: 5) {
                app.tabBars.buttons["Home"].tap()
            }

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
}
