import XCTest
@testable import OpenDisk

final class CleanupPlannerServiceTests: XCTestCase {
    private let planner = CleanupPlannerService()

    func testKeepUserDataModeExcludesUserDataArtifacts() {
        let app = makeSampleApp()

        let plan = planner.makePlan(for: app, mode: .keepUserData)

        XCTAssertEqual(plan.candidates.count, 1)
        XCTAssertEqual(plan.candidates[0].selectedArtifacts.count, 2)
        XCTAssertFalse(plan.candidates[0].selectedArtifacts.contains(where: { $0.groupKind == .userData }))
    }

    func testRemoveEverythingIncludesAllArtifacts() {
        let app = makeSampleApp()

        let plan = planner.makePlan(for: app, mode: .removeEverything)

        XCTAssertEqual(plan.fileCount, 3)
        XCTAssertEqual(plan.totalBytes, 8_000)
    }

    private func makeSampleApp() -> InstalledApp {
        InstalledApp(
            id: "app",
            displayName: "Sample",
            bundleID: "com.example.sample",
            bundlePath: "/Applications/Sample.app",
            executablePath: nil,
            lastUsedDate: nil,
            bundleSizeBytes: 1000,
            artifacts: [
                AssociatedArtifact(path: "/tmp/cache", groupKind: .cache, safetyLevel: .safe, sizeBytes: 2000, isDirectory: true),
                AssociatedArtifact(path: "/tmp/user", groupKind: .userData, safetyLevel: .review, sizeBytes: 3000, isDirectory: true),
                AssociatedArtifact(path: "/tmp/preferences.plist", groupKind: .preferences, safetyLevel: .review, sizeBytes: 3000, isDirectory: false)
            ]
        )
    }
}
