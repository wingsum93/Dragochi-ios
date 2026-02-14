//
//  DragochiUITests.swift
//  DragochiUITests
//
//  Created by eric ho on 11/2/2026.
//

import XCTest

final class DragochiUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureHome() throws {
        let app = launchAppForScreenshots()

        waitForElementToAppear(app.staticTexts["Quick Track"])
        attachScreenshot(from: app, named: "home.png")
    }

    @MainActor
    func testCaptureHistory() throws {
        let app = launchAppForScreenshots()

        app.tabBars.buttons["History"].tap()
        let totalPlaytimeLabel = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "TOTAL PLAYTIME:")).firstMatch
        waitForElementToAppear(totalPlaytimeLabel)
        attachScreenshot(from: app, named: "history.png")
    }

    @MainActor
    func testCaptureStats() throws {
        let app = launchAppForScreenshots()

        app.tabBars.buttons["Stats"].tap()
        waitForElementToAppear(app.staticTexts["Total Playtime"])
        attachScreenshot(from: app, named: "stats.png")
    }

    @MainActor
    func testCaptureSettings() throws {
        let app = launchAppForScreenshots()

        app.tabBars.buttons["Settings"].tap()
        waitForElementToAppear(app.staticTexts["iCloud Sync"])
        attachScreenshot(from: app, named: "settings.png")
    }

    @MainActor
    func testCaptureAddSession() throws {
        let app = launchAppForScreenshots()

        waitForElementToAppear(app.staticTexts["Quick Track"])

        let startButton = app.buttons["action.startTracking"]
        waitForElementToAppear(startButton)
        startButton.tap()

        waitForElementToAppear(app.staticTexts["Session Setup"])
        waitForElementToAppear(app.staticTexts["Game Played"])
        sleep(4)
        XCTAssertTrue(app.staticTexts["Game Played"].exists)
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
}
