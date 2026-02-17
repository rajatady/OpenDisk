import Foundation
import Combine

@MainActor
final class SmartCategoriesViewModel: ObservableObject {
    @Published private(set) var state = SmartCategoriesViewState(
        categories: [],
        isLoading: false,
        usedCachedResults: false,
        errorMessage: nil
    )
    @Published private(set) var quickCleanResult: CleanupExecutionResult?
    @Published private(set) var isExecutingQuickClean = false

    private let cleanupExecutor: CleanupExecutorProtocol
    private var loadedApps: [InstalledApp] = []

    init(container: AppContainer) {
        self.cleanupExecutor = container.cleanupExecutor
    }

    var totalSafeCleanupBytes: Int64 {
        state.categories.reduce(0) { $0 + $1.safeCleanupBytes }
    }

    var totalReviewCleanupBytes: Int64 {
        state.categories.reduce(0) { $0 + $1.reviewCleanupBytes }
    }

    nonisolated deinit {}

    func load(apps: [InstalledApp], usedCachedResults: Bool) {
        state.isLoading = true
        state.errorMessage = nil
        quickCleanResult = nil

        loadedApps = apps
        state.categories = Self.buildCategories(from: apps)
        state.usedCachedResults = usedCachedResults
        state.isLoading = false
    }

    func executeQuickClean() async {
        let safeArtifacts = loadedApps.flatMap(\.artifacts).filter { $0.safetyLevel == .safe }
        guard !safeArtifacts.isEmpty else {
            quickCleanResult = CleanupExecutionResult(reclaimedBytes: 0, removedPaths: [], failures: [])
            return
        }

        let cleanupApp = InstalledApp(
            id: "smart-category-safe-clean",
            displayName: "Smart Category Safe Clean",
            bundleID: "internal.smart.safe.clean",
            bundlePath: "/",
            executablePath: nil,
            lastUsedDate: nil,
            bundleSizeBytes: 0,
            artifacts: safeArtifacts
        )
        let candidate = CleanupCandidate(app: cleanupApp, mode: .removeEverything, selectedArtifacts: safeArtifacts)
        let plan = CleanupPlan(candidates: [candidate])

        isExecutingQuickClean = true
        let result = await cleanupExecutor.execute(plan: plan)
        isExecutingQuickClean = false
        quickCleanResult = result
    }

    static func buildCategories(from apps: [InstalledApp]) -> [SmartCategory] {
        struct Totals {
            var totalBytes: Int64 = 0
            var itemCount: Int = 0
            var safeBytes: Int64 = 0
            var reviewBytes: Int64 = 0
            var riskyBytes: Int64 = 0

            mutating func addArtifact(_ artifact: AssociatedArtifact) {
                totalBytes += artifact.sizeBytes
                itemCount += 1
                switch artifact.safetyLevel {
                case .safe:
                    safeBytes += artifact.sizeBytes
                case .review:
                    reviewBytes += artifact.sizeBytes
                case .risky:
                    riskyBytes += artifact.sizeBytes
                }
            }
        }

        var buckets: [SmartCategoryKind: Totals] = [:]
        SmartCategoryKind.allCases.forEach { buckets[$0] = Totals() }

        for app in apps {
            buckets[.applications, default: Totals()].totalBytes += app.bundleSizeBytes
            buckets[.applications, default: Totals()].itemCount += 1

            for artifact in app.artifacts {
                let key: SmartCategoryKind
                switch artifact.groupKind {
                case .appBundle:
                    key = .applications
                case .userData:
                    key = .userData
                case .cache:
                    key = .caches
                case .preferences:
                    key = .preferences
                case .systemIntegration:
                    key = .systemIntegration
                }
                buckets[key, default: Totals()].addArtifact(artifact)
            }
        }

        return SmartCategoryKind.allCases.map { kind in
            let totals = buckets[kind, default: Totals()]
            return SmartCategory(
                kind: kind,
                totalBytes: totals.totalBytes,
                itemCount: totals.itemCount,
                safeCleanupBytes: totals.safeBytes,
                reviewCleanupBytes: totals.reviewBytes,
                riskyCleanupBytes: totals.riskyBytes
            )
        }
        .sorted(by: { $0.totalBytes > $1.totalBytes })
    }
}
