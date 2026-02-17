import Foundation

nonisolated final class AppContainer {
    let permissionService: PermissionServiceProtocol
    let onboardingStore: OnboardingStateStoreProtocol
    let aiCapabilityService: AICapabilityServiceProtocol
    let installedAppCatalogService: InstalledAppCatalogServiceProtocol
    let appArtifactResolver: AppArtifactResolverProtocol
    let cleanupPlanner: CleanupPlannerProtocol
    let cleanupExecutor: CleanupExecutorProtocol
    let profileInferenceService: ProfileInferenceServiceProtocol
    let semanticUnitDetector: SemanticUnitDetectorProtocol
    let recommendationRanker: RecommendationRankerProtocol
    let metadataDiscoveryService: MetadataDiscoveryServiceProtocol
    let recommendationsCacheStore: RecommendationsCacheStoreProtocol
    let storageMapCacheStore: StorageMapCacheStoreProtocol
    let diskScanner: DiskScannerProtocol
    let timelineStore: TimelineStoreProtocol
    let activityMonitor: ActivityMonitorServiceProtocol
    let automationScheduler: AutomationSchedulerProtocol

    init(
        permissionService: PermissionServiceProtocol,
        onboardingStore: OnboardingStateStoreProtocol,
        aiCapabilityService: AICapabilityServiceProtocol,
        installedAppCatalogService: InstalledAppCatalogServiceProtocol,
        appArtifactResolver: AppArtifactResolverProtocol,
        cleanupPlanner: CleanupPlannerProtocol,
        cleanupExecutor: CleanupExecutorProtocol,
        profileInferenceService: ProfileInferenceServiceProtocol,
        semanticUnitDetector: SemanticUnitDetectorProtocol,
        recommendationRanker: RecommendationRankerProtocol,
        metadataDiscoveryService: MetadataDiscoveryServiceProtocol,
        recommendationsCacheStore: RecommendationsCacheStoreProtocol,
        storageMapCacheStore: StorageMapCacheStoreProtocol,
        diskScanner: DiskScannerProtocol,
        timelineStore: TimelineStoreProtocol,
        activityMonitor: ActivityMonitorServiceProtocol,
        automationScheduler: AutomationSchedulerProtocol
    ) {
        self.permissionService = permissionService
        self.onboardingStore = onboardingStore
        self.aiCapabilityService = aiCapabilityService
        self.installedAppCatalogService = installedAppCatalogService
        self.appArtifactResolver = appArtifactResolver
        self.cleanupPlanner = cleanupPlanner
        self.cleanupExecutor = cleanupExecutor
        self.profileInferenceService = profileInferenceService
        self.semanticUnitDetector = semanticUnitDetector
        self.recommendationRanker = recommendationRanker
        self.metadataDiscoveryService = metadataDiscoveryService
        self.recommendationsCacheStore = recommendationsCacheStore
        self.storageMapCacheStore = storageMapCacheStore
        self.diskScanner = diskScanner
        self.timelineStore = timelineStore
        self.activityMonitor = activityMonitor
        self.automationScheduler = automationScheduler
    }

    @MainActor
    static func make(processInfo: ProcessInfo = .processInfo) -> AppContainer {
        if processInfo.environment["OPENDISK_USE_MOCKS"] == "1" {
            return .mock()
        }

        let sizeCalculator = FileSystemSizeCalculator()
        let permissionService = PermissionService(processInfo: processInfo)
        let onboardingStore = UserDefaultsOnboardingStateStore(defaults: .standard)
        let aiCapabilityService = AICapabilityService(processInfo: processInfo)
        let appCatalogService = InstalledAppCatalogService(sizeCalculator: sizeCalculator)
        let artifactResolver = AppArtifactResolverService(sizeCalculator: sizeCalculator)
        let recommendationsCache = RecommendationsCacheStore()
        let storageMapCache = StorageMapCacheStore()
        let activityMonitor = ActivityMonitorService()

        return AppContainer(
            permissionService: permissionService,
            onboardingStore: onboardingStore,
            aiCapabilityService: aiCapabilityService,
            installedAppCatalogService: appCatalogService,
            appArtifactResolver: artifactResolver,
            cleanupPlanner: CleanupPlannerService(),
            cleanupExecutor: CleanupExecutorService(),
            profileInferenceService: ProfileInferenceService(),
            semanticUnitDetector: SemanticUnitDetectorService(sizeCalculator: sizeCalculator),
            recommendationRanker: RecommendationRankerService(),
            metadataDiscoveryService: MetadataDiscoveryService(),
            recommendationsCacheStore: recommendationsCache,
            storageMapCacheStore: storageMapCache,
            diskScanner: DiskScannerService(sizeCalculator: sizeCalculator),
            timelineStore: TimelineStore(),
            activityMonitor: activityMonitor,
            automationScheduler: AutomationSchedulerService()
        )
    }

    @MainActor
    static func mock() -> AppContainer {
        let mockApps = MockInstalledAppCatalogService.sampleApps
        let artifactResolver = MockArtifactResolverService(sampleApps: mockApps)

        return AppContainer(
            permissionService: MockPermissionService(),
            onboardingStore: UserDefaultsOnboardingStateStore(defaults: .standard),
            aiCapabilityService: MockAICapabilityService(),
            installedAppCatalogService: MockInstalledAppCatalogService(apps: mockApps),
            appArtifactResolver: artifactResolver,
            cleanupPlanner: CleanupPlannerService(),
            cleanupExecutor: MockCleanupExecutorService(),
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
