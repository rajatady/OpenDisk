import Foundation
import Combine

@MainActor
final class RootViewModel: ObservableObject {
    @Published var selectedSection: AppSection = .appManager {
        didSet {
            guard AppSection.productionReadySections.contains(selectedSection) else {
                selectedSection = .appManager
                return
            }
        }
    }
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
        await appManagerViewModel.loadApps()
        smartCategoriesViewModel.load(
            apps: appManagerViewModel.state.apps,
            usedCachedResults: appManagerViewModel.state.usedCachedResults
        )
    }
}
