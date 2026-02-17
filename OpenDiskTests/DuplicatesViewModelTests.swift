import XCTest
@testable import OpenDisk

@MainActor
final class DuplicatesViewModelTests: XCTestCase {
    func testLoadComputesDuplicateGroupsDeterministically() {
        let viewModel = DuplicatesViewModel()
        let apps = makeFixtureApps()

        viewModel.load(apps: apps, usedCachedResults: true)

        XCTAssertTrue(viewModel.state.usedCachedResults)
        XCTAssertEqual(viewModel.state.duplicateGroups.count, 1)
        XCTAssertEqual(viewModel.state.duplicateGroups.first?.duplicates.count, 2)
        XCTAssertEqual(viewModel.state.duplicateGroups.first?.totalBytes, 4_000)
        XCTAssertEqual(viewModel.potentialDuplicateReclaim, 2_000)

        let paths = viewModel.state.duplicateGroups.first?.duplicates.map(\.path) ?? []
        XCTAssertEqual(paths, paths.sorted())
    }

    func testLoadSortsLargeItemsDescendingBySize() {
        let viewModel = DuplicatesViewModel()
        let apps = makeFixtureApps()

        viewModel.load(apps: apps, usedCachedResults: false)

        let sizes = viewModel.state.largeItems.map(\.sizeBytes)
        XCTAssertEqual(sizes, sizes.sorted(by: >))
        XCTAssertEqual(viewModel.state.largeItems.first?.title, "App A")
    }

    private func makeFixtureApps() -> [InstalledApp] {
        let appA = InstalledApp(
            id: "app-a",
            displayName: "App A",
            bundleID: "com.example.appa",
            bundlePath: "/Applications/AppA.app",
            executablePath: nil,
            lastUsedDate: nil,
            bundleSizeBytes: 10_000,
            artifacts: [
                AssociatedArtifact(
                    path: "/Users/test/runA/checkpoint.bin",
                    groupKind: .userData,
                    safetyLevel: .review,
                    sizeBytes: 2_000,
                    isDirectory: false
                ),
                AssociatedArtifact(
                    path: "/Users/test/runA/cache.db",
                    groupKind: .cache,
                    safetyLevel: .safe,
                    sizeBytes: 1_200,
                    isDirectory: false
                )
            ]
        )
        let appB = InstalledApp(
            id: "app-b",
            displayName: "App B",
            bundleID: "com.example.appb",
            bundlePath: "/Applications/AppB.app",
            executablePath: nil,
            lastUsedDate: nil,
            bundleSizeBytes: 8_000,
            artifacts: [
                AssociatedArtifact(
                    path: "/Users/test/runB/checkpoint.bin",
                    groupKind: .userData,
                    safetyLevel: .review,
                    sizeBytes: 2_000,
                    isDirectory: false
                ),
                AssociatedArtifact(
                    path: "/Users/test/runB/model.bin",
                    groupKind: .userData,
                    safetyLevel: .review,
                    sizeBytes: 3_000,
                    isDirectory: false
                )
            ]
        )
        return [appA, appB]
    }
}
