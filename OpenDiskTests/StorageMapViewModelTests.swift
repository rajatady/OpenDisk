import XCTest
@testable import OpenDisk

@MainActor
final class StorageMapViewModelTests: XCTestCase {
    func testSecondLoadUsesStorageMapCache() async {
        let scanner = CountingDiskScanner()
        let cache = MemoryStorageMapCacheStore()
        let viewModel = StorageMapViewModel(container: makeContainer(scanner: scanner, cache: cache))

        await viewModel.load(scope: .home)
        let firstCount = await scanner.callCount

        await viewModel.load(scope: .home)
        let secondCount = await scanner.callCount

        XCTAssertEqual(firstCount, 1)
        XCTAssertEqual(secondCount, 1)
        XCTAssertTrue(viewModel.state.usedCachedResults)
        XCTAssertNotNil(viewModel.state.root)
    }

    func testForceRefreshBypassesCache() async {
        let scanner = CountingDiskScanner()
        let cache = MemoryStorageMapCacheStore()
        let viewModel = StorageMapViewModel(container: makeContainer(scanner: scanner, cache: cache))

        await viewModel.load(scope: .home)
        await viewModel.load(scope: .home, forceRefresh: true)
        let callCount = await scanner.callCount

        XCTAssertEqual(callCount, 2)
        XCTAssertFalse(viewModel.state.usedCachedResults)
    }

    private func makeContainer(scanner: DiskScannerProtocol, cache: StorageMapCacheStoreProtocol) -> AppContainer {
        let apps = MockInstalledAppCatalogService.sampleApps
        let defaults = UserDefaults(suiteName: "storage-map-tests-\(UUID().uuidString)") ?? .standard

        return AppContainer(
            permissionService: MockPermissionService(),
            onboardingStore: UserDefaultsOnboardingStateStore(defaults: defaults),
            aiCapabilityService: MockAICapabilityService(),
            installedAppCatalogService: MockInstalledAppCatalogService(apps: apps),
            appArtifactResolver: MockArtifactResolverService(sampleApps: apps),
            cleanupPlanner: CleanupPlannerService(),
            cleanupExecutor: MockCleanupExecutorService(),
            profileInferenceService: ProfileInferenceService(),
            semanticUnitDetector: MockSemanticUnitDetectorService(),
            recommendationRanker: RecommendationRankerService(),
            metadataDiscoveryService: MockMetadataDiscoveryService(),
            recommendationsCacheStore: MockRecommendationsCacheStore(),
            storageMapCacheStore: cache,
            diskScanner: scanner,
            timelineStore: TimelineStore(),
            activityMonitor: MockActivityMonitorService(),
            automationScheduler: AutomationSchedulerService()
        )
    }
}

actor CountingDiskScanner: DiskScannerProtocol {
    private(set) var callCount = 0

    func scan(root: URL) async throws -> DiskNode {
        callCount += 1
        return DiskNode(
            id: root.path,
            name: root.lastPathComponent,
            path: root.path,
            sizeBytes: 10_000,
            isDirectory: true,
            children: [
                DiskNode(
                    id: root.appendingPathComponent("A").path,
                    name: "A",
                    path: root.appendingPathComponent("A").path,
                    sizeBytes: 6_000,
                    isDirectory: true,
                    children: []
                ),
                DiskNode(
                    id: root.appendingPathComponent("B").path,
                    name: "B",
                    path: root.appendingPathComponent("B").path,
                    sizeBytes: 4_000,
                    isDirectory: true,
                    children: []
                )
            ]
        )
    }
}

actor MemoryStorageMapCacheStore: StorageMapCacheStoreProtocol {
    private var entries: [String: StorageMapCacheEntry] = [:]

    func load(key: String, maxAge: TimeInterval) async -> StorageMapCacheEntry? {
        guard let entry = entries[key], Date().timeIntervalSince(entry.createdAt) <= maxAge else {
            return nil
        }
        return entry
    }

    func save(entry: StorageMapCacheEntry) async {
        entries[entry.key] = entry
    }
}
