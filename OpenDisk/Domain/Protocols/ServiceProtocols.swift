import Foundation

protocol PermissionServiceProtocol: Sendable {
    func permissionStatus() async -> PermissionStatus
    func openSystemSettingsForFullDiskAccess()
}

protocol OnboardingStateStoreProtocol: AnyObject, Sendable {
    var isCompleted: Bool { get set }
    var lastCompletedAt: Date? { get set }
    var selectedScope: ScanScope { get set }
}

protocol AICapabilityServiceProtocol: Sendable {
    func capabilityStatus() -> AICapabilityStatus
}

protocol InstalledAppCatalogServiceProtocol: Sendable {
    func fetchInstalledApps(onProgress: ((AppScanProgress) -> Void)?) async throws -> [InstalledApp]
}

extension InstalledAppCatalogServiceProtocol {
    func fetchInstalledApps() async throws -> [InstalledApp] {
        try await fetchInstalledApps(onProgress: nil)
    }
}

protocol AppCatalogFetchInfoProvider: Sendable {
    func latestFetchInfo() async -> AppCatalogFetchInfo
}

protocol AppArtifactResolverProtocol: Sendable {
    func artifacts(for app: InstalledApp) async -> [AssociatedArtifact]
    func orphanArtifacts(existingBundleIDs: Set<String>) async -> [AssociatedArtifact]
}

protocol CleanupPlannerProtocol: Sendable {
    func makePlan(for app: InstalledApp, mode: CleanupMode) -> CleanupPlan
}

protocol CleanupExecutorProtocol: Sendable {
    func execute(plan: CleanupPlan) async -> CleanupExecutionResult
}

protocol ProfileInferenceServiceProtocol: Sendable {
    func inferProfile(apps: [InstalledApp], metadata: [FileMetadata]) async -> UserProfile
}

protocol MetadataDiscoveryServiceProtocol: Sendable {
    func collectMetadata(in rootURL: URL, maxDepth: Int, maxSamples: Int) async -> [FileMetadata]
}

protocol SemanticUnitDetectorProtocol: Sendable {
    func detectUnits(in rootURL: URL) async -> [SemanticCleanupUnit]
}

protocol RecommendationRankerProtocol: Sendable {
    func rank(profile: UserProfile, apps: [InstalledApp], semanticUnits: [SemanticCleanupUnit]) -> [Recommendation]
}

protocol RecommendationsCacheStoreProtocol: Sendable {
    func load(key: String, maxAge: TimeInterval) async -> RecommendationsCacheEntry?
    func save(entry: RecommendationsCacheEntry) async
}

protocol DiskScannerProtocol: Sendable {
    func scan(root: URL) async throws -> DiskNode
}

protocol TimelineStoreProtocol: Sendable {
    func save(snapshot: DiskSnapshot) async
    func snapshots() async -> [DiskSnapshot]
}

protocol ActivityMonitorServiceProtocol: Sendable {
    func record(sample: ActivitySample) async
    func samples(limit: Int?) async -> [ActivitySample]
}

protocol AutomationSchedulerProtocol: Sendable {
    func schedule(rules: [AutomationRule]) async
}
