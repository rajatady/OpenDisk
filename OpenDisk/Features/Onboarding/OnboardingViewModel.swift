import Foundation
import Combine
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var state: OnboardingViewState

    private let permissionService: PermissionServiceProtocol
    private let aiCapabilityService: AICapabilityServiceProtocol
    private let appCatalogService: InstalledAppCatalogServiceProtocol
    private let onboardingStore: OnboardingStateStoreProtocol

    let totalSteps = 5

    init(container: AppContainer) {
        self.permissionService = container.permissionService
        self.aiCapabilityService = container.aiCapabilityService
        self.appCatalogService = container.installedAppCatalogService
        self.onboardingStore = container.onboardingStore

        self.state = OnboardingViewState(
            currentStep: 0,
            permissionStatus: .notDetermined,
            aiStatus: container.aiCapabilityService.capabilityStatus(),
            selectedScope: container.onboardingStore.selectedScope,
            quickScanSummary: "",
            quickScanMessage: "",
            quickScanProgress: nil,
            isRunningQuickScan: false,
            canFinish: false
        )
    }

    func refreshPermissionStatus() async {
        state.permissionStatus = await permissionService.permissionStatus()
    }

    func refreshAICapability() {
        state.aiStatus = aiCapabilityService.capabilityStatus()
    }

    func openSystemSettings() {
        permissionService.openSystemSettingsForFullDiskAccess()
    }

    func setScope(_ scope: ScanScope) {
        state.selectedScope = scope
        onboardingStore.selectedScope = scope
    }

    func runQuickScan() async {
        state.isRunningQuickScan = true
        state.quickScanMessage = "Preparing quick scan..."
        state.quickScanProgress = nil
        defer { state.isRunningQuickScan = false }

        do {
            let apps = try await appCatalogService.fetchInstalledApps { [weak self] progress in
                guard let self else { return }
                self.state.quickScanMessage = progress.message
                self.state.quickScanProgress = progress.fractionCompleted
            }

            let totalBytes = apps.reduce(Int64(0)) { $0 + $1.bundleSizeBytes }
            state.quickScanSummary = "Detected \(apps.count) apps with \(Formatting.bytes(totalBytes)) in app bundles."
            state.quickScanMessage = "Quick scan complete."
            state.quickScanProgress = 1
            state.canFinish = true
        } catch {
            state.quickScanSummary = "Quick scan failed: \(error.localizedDescription)"
            state.quickScanMessage = "Quick scan failed."
            state.quickScanProgress = nil
            state.canFinish = false
        }
    }

    func canAdvance(from step: Int) -> Bool {
        switch step {
        case 1:
            return state.permissionStatus == .authorized
        case 2:
            return state.aiStatus.isSupported
        case 4:
            return state.canFinish
        default:
            return true
        }
    }

    func next() {
        guard state.currentStep < totalSteps - 1 else { return }
        guard canAdvance(from: state.currentStep) else { return }
        withAnimation(ODAnimation.smooth) {
            state.currentStep += 1
        }
    }

    func previous() {
        guard state.currentStep > 0 else { return }
        withAnimation(ODAnimation.smooth) {
            state.currentStep -= 1
        }
    }

    func complete() {
        onboardingStore.isCompleted = true
        onboardingStore.lastCompletedAt = Date()
        onboardingStore.selectedScope = state.selectedScope
    }
}
