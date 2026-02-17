import AppKit
import XCTest

final class OpenDiskUITests: XCTestCase {
    private let appBundleID = "com.trymagically.OpenDisk"

    override func setUpWithError() throws {
        continueAfterFailure = false
        terminateRunningAppInstances()
    }

    private func terminateRunningAppInstances() {
        forceKillLingeringOpenDiskProcesses()

        let deadline = Date().addingTimeInterval(2.0)

        for app in NSRunningApplication.runningApplications(withBundleIdentifier: appBundleID) {
            _ = app.terminate()
        }

        while Date() < deadline {
            if NSRunningApplication.runningApplications(withBundleIdentifier: appBundleID).isEmpty {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        for app in NSRunningApplication.runningApplications(withBundleIdentifier: appBundleID) {
            app.forceTerminate()
        }

        forceKillLingeringOpenDiskProcesses()
    }

    private func forceKillLingeringOpenDiskProcesses() {
        let commands: [[String]] = [
            ["/usr/bin/killall", "-9", "OpenDisk"],
            ["/usr/bin/pkill", "-9", "-f", "OpenDisk.app/Contents/MacOS/OpenDisk"]
        ]

        for command in commands {
            guard let executable = command.first else { continue }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = Array(command.dropFirst())
            process.standardOutput = Pipe()
            process.standardError = Pipe()
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                continue
            }
        }
    }

    private func launchApp(resetOnboarding: Bool) throws -> XCUIApplication {
        if !NSRunningApplication.runningApplications(withBundleIdentifier: appBundleID).isEmpty {
            throw XCTSkip("Skipping: an external OpenDisk process is still attached and cannot be safely terminated by XCTest.")
        }

        let app = XCUIApplication()
        app.launchEnvironment["OPENDISK_USE_MOCKS"] = "1"
        if resetOnboarding {
            app.launchEnvironment["OPENDISK_RESET_ONBOARDING"] = "1"
            app.launchEnvironment["OPENDISK_PERMISSION_STATUS"] = "authorized"
            app.launchEnvironment["OPENDISK_AI_SUPPORTED"] = "1"
        } else {
            app.launchEnvironment["OPENDISK_FORCE_COMPLETE_ONBOARDING"] = "1"
        }
        app.launch()
        return app
    }

    @MainActor
    func testFirstBootOnboardingFlow() throws {
        let app = try launchApp(resetOnboarding: true)

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
        let app = try launchApp(resetOnboarding: false)

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
        let app = try launchApp(resetOnboarding: false)

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
        let app = try launchApp(resetOnboarding: false)

        let activityItem = app.staticTexts["Activity"]
        XCTAssertTrue(activityItem.waitForExistence(timeout: 5))
        activityItem.tap()

        XCTAssertTrue(app.staticTexts["Activity Monitor"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["activity_chart"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["activity_disk_trend_chart"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSidebarNavigationToStorageMapCategoriesAndDuplicates() throws {
        let app = try launchApp(resetOnboarding: false)

        let storageMapItem = app.staticTexts["Storage Map"]
        XCTAssertTrue(storageMapItem.waitForExistence(timeout: 5))
        storageMapItem.tap()
        XCTAssertTrue(app.staticTexts["storage_map_title"].waitForExistence(timeout: 5))

        let firstTile = app.buttons["storage_map_tile_0"]
        XCTAssertTrue(firstTile.waitForExistence(timeout: 5))
        firstTile.tap()

        let backButton = app.buttons["storage_map_back_button"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        XCTAssertTrue(backButton.isEnabled)
        backButton.tap()

        let categoriesItem = app.staticTexts["Categories"]
        XCTAssertTrue(categoriesItem.waitForExistence(timeout: 5))
        categoriesItem.tap()
        XCTAssertTrue(app.staticTexts["smart_categories_title"].waitForExistence(timeout: 5))

        let duplicatesItem = app.staticTexts["Duplicates"]
        XCTAssertTrue(duplicatesItem.waitForExistence(timeout: 5))
        duplicatesItem.tap()
        XCTAssertTrue(app.staticTexts["duplicates_title"].waitForExistence(timeout: 5))

        let appManagerItem = app.staticTexts["App Manager"]
        XCTAssertTrue(appManagerItem.waitForExistence(timeout: 5))
        appManagerItem.tap()
        XCTAssertTrue(app.staticTexts["Installed Apps"].waitForExistence(timeout: 5))
    }
}
