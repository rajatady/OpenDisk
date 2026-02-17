import Foundation

struct MockPermissionService: PermissionServiceProtocol {
    func permissionStatus() async -> PermissionStatus {
        .authorized
    }

    func openSystemSettingsForFullDiskAccess() {}
}

struct MockAICapabilityService: AICapabilityServiceProtocol {
    func capabilityStatus() -> AICapabilityStatus {
        .supported
    }
}

struct MockInstalledAppCatalogService: InstalledAppCatalogServiceProtocol {
    let apps: [InstalledApp]
    let source: CacheSource

    static let sampleApps: [InstalledApp] = [
        InstalledApp(
            id: "com.apple.dt.xcode:/Applications/Xcode.app",
            displayName: "Xcode",
            bundleID: "com.apple.dt.Xcode",
            bundlePath: "/Applications/Xcode.app",
            executablePath: "/Applications/Xcode.app/Contents/MacOS/Xcode",
            lastUsedDate: Date().addingTimeInterval(-86000),
            bundleSizeBytes: 15_400_000_000,
            artifacts: [
                AssociatedArtifact(path: "~/Library/Developer/Xcode/DerivedData", groupKind: .cache, safetyLevel: .safe, sizeBytes: 8_600_000_000, isDirectory: true),
                AssociatedArtifact(path: "~/Library/Developer/Xcode/Archives", groupKind: .userData, safetyLevel: .review, sizeBytes: 12_300_000_000, isDirectory: true)
            ]
        ),
        InstalledApp(
            id: "com.figma.Desktop:/Applications/Figma.app",
            displayName: "Figma",
            bundleID: "com.figma.Desktop",
            bundlePath: "/Applications/Figma.app",
            executablePath: "/Applications/Figma.app/Contents/MacOS/Figma",
            lastUsedDate: Date().addingTimeInterval(-300000),
            bundleSizeBytes: 420_000_000,
            artifacts: [
                AssociatedArtifact(path: "~/Library/Caches/com.figma.Desktop", groupKind: .cache, safetyLevel: .safe, sizeBytes: 1_200_000_000, isDirectory: true),
                AssociatedArtifact(path: "~/Library/Application Support/Figma", groupKind: .userData, safetyLevel: .review, sizeBytes: 820_000_000, isDirectory: true)
            ]
        ),
        InstalledApp(
            id: "org.python.python:/Applications/Python.app",
            displayName: "Python",
            bundleID: "org.python.python",
            bundlePath: "/Applications/Python.app",
            executablePath: nil,
            lastUsedDate: Date().addingTimeInterval(-50000),
            bundleSizeBytes: 160_000_000,
            artifacts: [
                AssociatedArtifact(path: "~/experiments/run_42/checkpoints", groupKind: .userData, safetyLevel: .review, sizeBytes: 22_000_000_000, isDirectory: true)
            ]
        )
    ]

    init(apps: [InstalledApp], source: CacheSource = .live) {
        self.apps = apps
        self.source = source
    }

    func fetchInstalledApps(onProgress: ((AppScanProgress) -> Void)? = nil) async throws -> [InstalledApp] {
        onProgress?(AppScanProgress(message: "Loading sample apps...", completed: 0, total: 1))
        onProgress?(AppScanProgress(message: "Loaded sample apps.", completed: 1, total: 1))
        return apps
    }
}

extension MockInstalledAppCatalogService: AppCatalogFetchInfoProvider {
    func latestFetchInfo() async -> AppCatalogFetchInfo {
        AppCatalogFetchInfo(source: source, fetchedAt: Date())
    }
}

struct MockArtifactResolverService: AppArtifactResolverProtocol {
    let sampleApps: [InstalledApp]

    func artifacts(for app: InstalledApp) async -> [AssociatedArtifact] {
        sampleApps.first(where: { $0.id == app.id })?.artifacts ?? []
    }

    func orphanArtifacts(existingBundleIDs: Set<String>) async -> [AssociatedArtifact] {
        _ = existingBundleIDs
        return [
            AssociatedArtifact(
                path: "~/Library/Caches/com.legacy.deletedapp",
                groupKind: .cache,
                safetyLevel: .safe,
                sizeBytes: 1_500_000_000,
                isDirectory: true
            )
        ]
    }
}

struct MockCleanupExecutorService: CleanupExecutorProtocol {
    func execute(plan: CleanupPlan) async -> CleanupExecutionResult {
        CleanupExecutionResult(
            reclaimedBytes: plan.totalBytes,
            removedPaths: plan.candidates.flatMap(\.selectedArtifacts).map(\.path),
            failures: []
        )
    }
}

struct MockSemanticUnitDetectorService: SemanticUnitDetectorProtocol {
    func detectUnits(in rootURL: URL) async -> [SemanticCleanupUnit] {
        _ = rootURL
        return [
            SemanticCleanupUnit(
                id: "unit:checkpoint",
                title: "checkpoints",
                path: "~/experiments/run_42/checkpoints",
                totalBytes: 22_000_000_000,
                fileCount: 14000,
                risk: .review,
                reason: "Training checkpoints can grow quickly."
            )
        ]
    }
}

struct MockMetadataDiscoveryService: MetadataDiscoveryServiceProtocol {
    func collectMetadata(in rootURL: URL, maxDepth: Int, maxSamples: Int) async -> [FileMetadata] {
        _ = rootURL
        _ = maxDepth
        _ = maxSamples
        return [
            FileMetadata(
                path: "~/experiments/run_42/checkpoints",
                sizeBytes: 22_000_000_000,
                fileCount: 14_000,
                depth: 5,
                extensionName: "ckpt"
            )
        ]
    }
}

actor MockRecommendationsCacheStore: RecommendationsCacheStoreProtocol {
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

actor MockStorageMapCacheStore: StorageMapCacheStoreProtocol {
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

actor MockActivityMonitorService: ActivityMonitorServiceProtocol {
    private var entries: [ActivitySample] = []

    func record(sample: ActivitySample) async {
        entries.append(sample)
    }

    func samples(limit: Int?) async -> [ActivitySample] {
        guard let limit, limit > 0 else {
            return entries
        }
        return Array(entries.suffix(limit))
    }
}

struct MockDiskScannerService: DiskScannerProtocol {
    func scan(root: URL) async throws -> DiskNode {
        DiskNode(
            id: root.path,
            name: root.lastPathComponent,
            path: root.path,
            sizeBytes: 48_000_000_000,
            isDirectory: true,
            children: [
                DiskNode(id: root.appendingPathComponent("Applications").path, name: "Applications", path: root.appendingPathComponent("Applications").path, sizeBytes: 20_000_000_000, isDirectory: true, children: []),
                DiskNode(id: root.appendingPathComponent("Users").path, name: "Users", path: root.appendingPathComponent("Users").path, sizeBytes: 28_000_000_000, isDirectory: true, children: [])
            ]
        )
    }
}
