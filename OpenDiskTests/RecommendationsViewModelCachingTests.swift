import XCTest
@testable import OpenDisk

@MainActor
final class RecommendationsViewModelCachingTests: XCTestCase {
    func testSecondLoadUsesCacheAndSkipsHeavyServices() async {
        let profileService = CountingProfileService()
        let semanticDetector = CountingSemanticDetector()
        let metadataService = CountingMetadataDiscoveryService()
        let cacheStore = MemoryRecommendationsCacheStore()
        let apps = MockInstalledAppCatalogService.sampleApps
        let resolver = MockArtifactResolverService(sampleApps: apps)

        let container = AppContainer(
            permissionService: MockPermissionService(),
            onboardingStore: UserDefaultsOnboardingStateStore(defaults: UserDefaults(suiteName: "recommendations-cache-tests") ?? .standard),
            aiCapabilityService: MockAICapabilityService(),
            installedAppCatalogService: MockInstalledAppCatalogService(apps: apps),
            appArtifactResolver: resolver,
            cleanupPlanner: CleanupPlannerService(),
            cleanupExecutor: MockCleanupExecutorService(),
            profileInferenceService: profileService,
            semanticUnitDetector: semanticDetector,
            recommendationRanker: RecommendationRankerService(),
            metadataDiscoveryService: metadataService,
            recommendationsCacheStore: cacheStore,
            storageMapCacheStore: MockStorageMapCacheStore(),
            diskScanner: MockDiskScannerService(),
            timelineStore: TimelineStore(),
            activityMonitor: MockActivityMonitorService(),
            automationScheduler: AutomationSchedulerService()
        )

        let viewModel = RecommendationsViewModel(container: container)

        await viewModel.load(apps: apps, scope: .home)
        let firstProfileCalls = await profileService.callCount
        let firstSemanticCalls = await semanticDetector.callCount
        let firstMetadataCalls = await metadataService.callCount

        await viewModel.load(apps: apps, scope: .home)
        let secondProfileCalls = await profileService.callCount
        let secondSemanticCalls = await semanticDetector.callCount
        let secondMetadataCalls = await metadataService.callCount

        XCTAssertEqual(firstProfileCalls, 1)
        XCTAssertEqual(firstSemanticCalls, 1)
        XCTAssertEqual(firstMetadataCalls, 1)

        XCTAssertEqual(secondProfileCalls, 1)
        XCTAssertEqual(secondSemanticCalls, 1)
        XCTAssertEqual(secondMetadataCalls, 1)
        XCTAssertTrue(viewModel.state.usedCachedResults)
    }
}

actor CountingProfileService: ProfileInferenceServiceProtocol {
    private(set) var callCount = 0

    func inferProfile(apps: [InstalledApp], metadata: [FileMetadata]) async -> UserProfile {
        _ = apps
        _ = metadata
        callCount += 1
        return UserProfile(kinds: [.webDeveloper], confidence: 0.85, evidence: [ProfileEvidence(reason: "test", weight: 0.85)])
    }
}

actor CountingSemanticDetector: SemanticUnitDetectorProtocol {
    private(set) var callCount = 0

    func detectUnits(in rootURL: URL) async -> [SemanticCleanupUnit] {
        _ = rootURL
        callCount += 1
        return [
            SemanticCleanupUnit(
                id: "unit",
                title: "node_modules",
                path: "/tmp/node_modules",
                totalBytes: 1_500_000_000,
                fileCount: 1200,
                risk: .review,
                reason: "Large dependencies"
            )
        ]
    }
}

actor CountingMetadataDiscoveryService: MetadataDiscoveryServiceProtocol {
    private(set) var callCount = 0

    func collectMetadata(in rootURL: URL, maxDepth: Int, maxSamples: Int) async -> [FileMetadata] {
        _ = rootURL
        _ = maxDepth
        _ = maxSamples
        callCount += 1
        return [
            FileMetadata(
                path: "/tmp/checkpoints",
                sizeBytes: 5_000_000_000,
                fileCount: 200,
                depth: 3,
                extensionName: "ckpt"
            )
        ]
    }
}

actor MemoryRecommendationsCacheStore: RecommendationsCacheStoreProtocol {
    private var entries: [String: RecommendationsCacheEntry] = [:]

    func load(key: String, maxAge: TimeInterval) async -> RecommendationsCacheEntry? {
        guard let entry = entries[key], Date().timeIntervalSince(entry.createdAt) <= maxAge else {
            return nil
        }
        return entry
    }

    func save(entry: RecommendationsCacheEntry) async {
        entries[entry.key] = entry
    }
}
