//
//  ScreenshotUITests.swift
//  ScreenshotUITests
//
//  Created by eric ho on 11/2/2026.
//

import XCTest

final class ScreenshotUITests: XCTestCase {
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

    @discardableResult
    private func launchAppForScreenshots() -> XCUIApplication {
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
}
