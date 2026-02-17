import XCTest
@testable import OpenDisk

@MainActor
final class SmartCategoriesViewModelTests: XCTestCase {
    func testLoadBuildsCategoriesAndTracksCachedFlag() {
        let apps = MockInstalledAppCatalogService.sampleApps
        let container = AppContainer.mock()
        let viewModel = SmartCategoriesViewModel(container: container)

        viewModel.load(apps: apps, usedCachedResults: true)

        XCTAssertFalse(viewModel.state.categories.isEmpty)
        XCTAssertTrue(viewModel.state.usedCachedResults)
        XCTAssertGreaterThan(viewModel.totalSafeCleanupBytes, 0)
        XCTAssertGreaterThan(viewModel.totalReviewCleanupBytes, 0)
        XCTAssertEqual(viewModel.state.categories.first?.kind, .userData)
    }

    func testExecuteQuickCleanPlansSafeArtifactsOnly() async {
        let apps = MockInstalledAppCatalogService.sampleApps
        let cleanupExecutor = CapturingCleanupExecutor()
        let viewModel = SmartCategoriesViewModel(
            container: makeContainer(cleanupExecutor: cleanupExecutor, apps: apps)
        )

        viewModel.load(apps: apps, usedCachedResults: false)
        await viewModel.executeQuickClean()

        let expectedSafeBytes = apps
            .flatMap(\.artifacts)
            .filter { $0.safetyLevel == .safe }
            .reduce(0) { $0 + $1.sizeBytes }
        let plan = await cleanupExecutor.capturedPlan()
        let selectedArtifacts = plan?.candidates.flatMap(\.selectedArtifacts) ?? []

        XCTAssertEqual(viewModel.quickCleanResult?.reclaimedBytes, expectedSafeBytes)
        XCTAssertFalse(selectedArtifacts.isEmpty)
        XCTAssertTrue(selectedArtifacts.allSatisfy { $0.safetyLevel == .safe })
    }

    private func makeContainer(
        cleanupExecutor: CleanupExecutorProtocol,
        apps: [InstalledApp]
    ) -> AppContainer {
        let defaults = UserDefaults(suiteName: "smart-categories-tests-\(UUID().uuidString)") ?? .standard

        return AppContainer(
            permissionService: MockPermissionService(),
            onboardingStore: UserDefaultsOnboardingStateStore(defaults: defaults),
            aiCapabilityService: MockAICapabilityService(),
            installedAppCatalogService: MockInstalledAppCatalogService(apps: apps),
            appArtifactResolver: MockArtifactResolverService(sampleApps: apps),
            cleanupPlanner: CleanupPlannerService(),
            cleanupExecutor: cleanupExecutor,
            profileInferenceService: ProfileInferenceService(),
            semanticUnitDetector: MockSemanticUnitDetectorService(),
            recommendationRanker: RecommendationRankerService(),
            metadataDiscoveryService: MockMetadataDiscoveryService(),
            recommendationsCacheStore: MockRecommendationsCacheStore(),
            storageMapCacheStore: MockStorageMapCacheStore(),
            diskScanner: MockDiskScannerService(),
            timelineStore: TimelineStore(),
            activityMonitor: MockActivityMonitorService(),
            automationScheduler: AutomationSchedulerService()
        )
    }
}

actor CapturingCleanupExecutor: CleanupExecutorProtocol {
    private var lastPlan: CleanupPlan?

    func execute(plan: CleanupPlan) async -> CleanupExecutionResult {
        lastPlan = plan
        return CleanupExecutionResult(
            reclaimedBytes: plan.totalBytes,
            removedPaths: plan.candidates.flatMap(\.selectedArtifacts).map(\.path),
            failures: []
        )
    }

    func capturedPlan() -> CleanupPlan? {
        lastPlan
    }
}
