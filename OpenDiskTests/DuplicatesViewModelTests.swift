import XCTest
@testable import OpenDisk

@MainActor
final class DuplicatesViewModelTests: XCTestCase {
    func testLoadComputesDuplicateGroupsDeterministically() {
        let viewModel = DuplicatesViewModel()
        let apps = makeFixtureApps()

        viewModel.load(apps: apps, diskRoot: nil, usedCachedResults: true)

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

        viewModel.load(apps: apps, diskRoot: nil, usedCachedResults: false)

        let sizes = viewModel.state.largeItems.map(\.sizeBytes)
        XCTAssertEqual(sizes, sizes.sorted(by: >))
        XCTAssertEqual(viewModel.state.largeItems.first?.title, "App A")
    }

    func testLoadUsesDiskFilesForDuplicateGroupsAndSkipsDirectoryOnlyMatches() {
        let viewModel = DuplicatesViewModel()
        let diskRoot = DiskNode(
            id: "/",
            name: "/",
            path: "/",
            sizeBytes: 80_000_000,
            isDirectory: true,
            children: [
                DiskNode(
                    id: "/runs-a",
                    name: "runs-a",
                    path: "/runs-a",
                    sizeBytes: 25_000_000,
                    isDirectory: true,
                    children: [
                        DiskNode(
                            id: "/runs-a/checkpoint.bin",
                            name: "checkpoint.bin",
                            path: "/runs-a/checkpoint.bin",
                            sizeBytes: 12_000_000,
                            isDirectory: false,
                            children: []
                        )
                    ]
                ),
                DiskNode(
                    id: "/runs-b",
                    name: "runs-b",
                    path: "/runs-b",
                    sizeBytes: 25_000_000,
                    isDirectory: true,
                    children: [
                        DiskNode(
                            id: "/runs-b/checkpoint.bin",
                            name: "checkpoint.bin",
                            path: "/runs-b/checkpoint.bin",
                            sizeBytes: 12_000_000,
                            isDirectory: false,
                            children: []
                        )
                    ]
                ),
                DiskNode(
                    id: "/logs-a",
                    name: "logs",
                    path: "/logs-a",
                    sizeBytes: 6_000_000,
                    isDirectory: true,
                    children: []
                ),
                DiskNode(
                    id: "/logs-b",
                    name: "logs",
                    path: "/logs-b",
                    sizeBytes: 6_000_000,
                    isDirectory: true,
                    children: []
                )
            ]
        )

        viewModel.load(apps: [], diskRoot: diskRoot, usedCachedResults: false)

        XCTAssertEqual(viewModel.state.duplicateGroups.count, 1)
        XCTAssertEqual(viewModel.state.duplicateGroups.first?.duplicates.count, 2)
        XCTAssertEqual(viewModel.state.duplicateGroups.first?.name, "checkpoint")
        XCTAssertTrue(viewModel.state.duplicateGroups.first?.duplicates.allSatisfy { $0.path.contains("checkpoint.bin") } == true)
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
