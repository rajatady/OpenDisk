import Foundation
import Combine

@MainActor
final class RootViewModel: ObservableObject {
    @Published var selectedSection: AppSection = .appManager
    @Published var shouldShowOnboarding: Bool

    let onboardingViewModel: OnboardingViewModel
    let appManagerViewModel: AppManagerViewModel
    let recommendationsViewModel: RecommendationsViewModel
    let storageMapViewModel: StorageMapViewModel
    let smartCategoriesViewModel: SmartCategoriesViewModel
    let duplicatesViewModel: DuplicatesViewModel
    let activityMonitorViewModel: ActivityMonitorViewModel

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        self.shouldShowOnboarding = !container.onboardingStore.isCompleted
        self.onboardingViewModel = OnboardingViewModel(container: container)
        self.appManagerViewModel = AppManagerViewModel(container: container)
        self.recommendationsViewModel = RecommendationsViewModel(container: container)
        self.storageMapViewModel = StorageMapViewModel(container: container)
        self.smartCategoriesViewModel = SmartCategoriesViewModel(container: container)
        self.duplicatesViewModel = DuplicatesViewModel()
        self.activityMonitorViewModel = ActivityMonitorViewModel(container: container)

        if ProcessInfo.processInfo.environment["OPENDISK_RESET_ONBOARDING"] == "1" {
            container.onboardingStore.isCompleted = false
            self.shouldShowOnboarding = true
        }

        if ProcessInfo.processInfo.environment["OPENDISK_FORCE_COMPLETE_ONBOARDING"] == "1" {
            container.onboardingStore.isCompleted = true
            self.shouldShowOnboarding = false
        }
    }

    var scanScope: ScanScope {
        container.onboardingStore.selectedScope
    }

    func completeOnboarding() async {
        shouldShowOnboarding = false
        await refreshAll()
    }

    func refreshAll() async {
        let start = Date()
        await appManagerViewModel.loadApps()
        await recommendationsViewModel.load(apps: appManagerViewModel.state.apps, scope: scanScope)
        await storageMapViewModel.load(scope: scanScope)
        smartCategoriesViewModel.load(
            apps: appManagerViewModel.state.apps,
            usedCachedResults: appManagerViewModel.state.usedCachedResults
        )
        duplicatesViewModel.load(
            apps: appManagerViewModel.state.apps,
            diskRoot: storageMapViewModel.state.root,
            usedCachedResults: appManagerViewModel.state.usedCachedResults
        )
        if let snapshot = makeCurrentSnapshot(scope: scanScope) {
            await activityMonitorViewModel.recordSnapshot(
                usedBytes: snapshot.usedBytes,
                freeBytes: snapshot.freeBytes,
                capturedAt: snapshot.capturedAt,
                refreshAfterSave: false
            )
        }
        let duration = Date().timeIntervalSince(start)

        await activityMonitorViewModel.recordSession(
            appCount: appManagerViewModel.state.apps.count,
            recommendationCount: recommendationsViewModel.state.recommendations.count,
            reclaimBytes: appManagerViewModel.totalReclaimPotential,
            scanDurationSeconds: duration,
            usedCachedCatalog: appManagerViewModel.state.usedCachedResults || recommendationsViewModel.state.usedCachedResults
        )
    }

    private func makeCurrentSnapshot(scope: ScanScope) -> DiskSnapshot? {
        let root: URL
        switch scope {
        case .home:
            root = URL(fileURLWithPath: NSHomeDirectory())
        case .applications:
            root = URL(fileURLWithPath: "/Applications")
        case .fullDisk:
            root = URL(fileURLWithPath: "/")
        }

        guard
            let attributes = try? FileManager.default.attributesOfFileSystem(forPath: root.path),
            let total = attributes[.systemSize] as? NSNumber,
            let free = attributes[.systemFreeSize] as? NSNumber
        else {
            return nil
        }

        let totalBytes = total.int64Value
        let freeBytes = max(0, free.int64Value)

        return DiskSnapshot(
            id: UUID(),
            capturedAt: Date(),
            usedBytes: max(0, totalBytes - freeBytes),
            freeBytes: freeBytes
        )
    }
}
