import Foundation
import Combine

@MainActor
final class RootViewModel: ObservableObject {
    @Published var selectedSection: AppSection = .appManager
    @Published var shouldShowOnboarding: Bool

    let onboardingViewModel: OnboardingViewModel
    let appManagerViewModel: AppManagerViewModel
    let recommendationsViewModel: RecommendationsViewModel
    let activityMonitorViewModel: ActivityMonitorViewModel

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        self.shouldShowOnboarding = !container.onboardingStore.isCompleted
        self.onboardingViewModel = OnboardingViewModel(container: container)
        self.appManagerViewModel = AppManagerViewModel(container: container)
        self.recommendationsViewModel = RecommendationsViewModel(container: container)
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
        let duration = Date().timeIntervalSince(start)

        await activityMonitorViewModel.recordSession(
            appCount: appManagerViewModel.state.apps.count,
            recommendationCount: recommendationsViewModel.state.recommendations.count,
            reclaimBytes: appManagerViewModel.totalReclaimPotential,
            scanDurationSeconds: duration,
            usedCachedCatalog: appManagerViewModel.state.usedCachedResults || recommendationsViewModel.state.usedCachedResults
        )
    }
}
