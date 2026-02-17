import XCTest

final class OpenDiskUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFirstBootOnboardingFlow() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OPENDISK_USE_MOCKS"] = "1"
        app.launchEnvironment["OPENDISK_RESET_ONBOARDING"] = "1"
        app.launchEnvironment["OPENDISK_PERMISSION_STATUS"] = "authorized"
        app.launchEnvironment["OPENDISK_AI_SUPPORTED"] = "1"
        app.launch()

        XCTAssertTrue(app.staticTexts["OpenDisk Setup"].waitForExistence(timeout: 5))

        let nextButton = app.buttons["onboarding_next_button"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))

        nextButton.tap()
        nextButton.tap()
        nextButton.tap()
        nextButton.tap()

        let startQuickScanButton = app.buttons["quickscan_start_button"]
        XCTAssertTrue(startQuickScanButton.waitForExistence(timeout: 5))
        startQuickScanButton.tap()

        let finishButton = app.buttons["onboarding_finish_button"]
        let exists = NSPredicate(format: "exists == true && isEnabled == true")
        expectation(for: exists, evaluatedWith: finishButton)
        waitForExpectations(timeout: 5)
        finishButton.tap()

        XCTAssertTrue(app.staticTexts["Installed Apps"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAppUninstallFlow() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OPENDISK_USE_MOCKS"] = "1"
        app.launchEnvironment["OPENDISK_FORCE_COMPLETE_ONBOARDING"] = "1"
        app.launch()

        let xcodeRow = app.buttons["app_row_com.apple.dt.Xcode"]
        XCTAssertTrue(xcodeRow.waitForExistence(timeout: 5))
        xcodeRow.tap()

        let uninstallButton = app.buttons["uninstall_button"]
        XCTAssertTrue(uninstallButton.waitForExistence(timeout: 5))
        uninstallButton.tap()

        let confirmButton = app.buttons["confirm_uninstall_button"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()

        XCTAssertTrue(app.staticTexts["cleanup_result_label"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOrphanScanAndCleanupFlow() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OPENDISK_USE_MOCKS"] = "1"
        app.launchEnvironment["OPENDISK_FORCE_COMPLETE_ONBOARDING"] = "1"
        app.launch()

        let scanButton = app.buttons["scan_orphans_button"]
        XCTAssertTrue(scanButton.waitForExistence(timeout: 5))
        scanButton.tap()

        let cleanButton = app.buttons["Clean Orphans"]
        XCTAssertTrue(cleanButton.waitForExistence(timeout: 5))
        cleanButton.tap()

        XCTAssertTrue(app.staticTexts["cleanup_result_label"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testActivityMonitorLoadsChartAndSessionList() throws {
        let app = XCUIApplication()
        app.launchEnvironment["OPENDISK_USE_MOCKS"] = "1"
        app.launchEnvironment["OPENDISK_FORCE_COMPLETE_ONBOARDING"] = "1"
        app.launch()

        let activityItem = app.staticTexts["Activity"]
        XCTAssertTrue(activityItem.waitForExistence(timeout: 5))
        activityItem.tap()

        XCTAssertTrue(app.staticTexts["Activity Monitor"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["activity_chart"].waitForExistence(timeout: 5))
    }
}
