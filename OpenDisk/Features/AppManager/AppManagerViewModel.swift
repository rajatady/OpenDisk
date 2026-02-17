import Foundation
import Combine

@MainActor
final class AppManagerViewModel: ObservableObject {
    enum SortOrder: String, CaseIterable, Identifiable {
        case size
        case name
        case lastUsed

        var id: String { rawValue }

        var title: String {
            switch self {
            case .size:
                return "Size"
            case .name:
                return "Name"
            case .lastUsed:
                return "Last Used"
            }
        }
    }

    @Published private(set) var state = AppManagerViewState(
        apps: [],
        filteredApps: [],
        isLoading: false,
        scanMessage: "",
        scanProgress: nil,
        usedCachedResults: false,
        lastScanAt: nil,
        errorMessage: nil
    )
    @Published var searchText = "" { didSet { applyFilters() } }
    @Published var sortOrder: SortOrder = .size { didSet { applyFilters() } }
    @Published var selectedAppID: String?
    @Published var orphanArtifacts: [AssociatedArtifact] = []
    @Published var uninstallState = UninstallFlowState(selectedMode: .removeEverything, plan: nil, executionResult: nil, isExecuting: false, errorMessage: nil)

    private let appCatalogService: InstalledAppCatalogServiceProtocol
    private let artifactResolver: AppArtifactResolverProtocol
    private let cleanupPlanner: CleanupPlannerProtocol
    private let cleanupExecutor: CleanupExecutorProtocol

    init(container: AppContainer) {
        self.appCatalogService = container.installedAppCatalogService
        self.artifactResolver = container.appArtifactResolver
        self.cleanupPlanner = container.cleanupPlanner
        self.cleanupExecutor = container.cleanupExecutor
    }

    var selectedApp: InstalledApp? {
        state.apps.first(where: { $0.id == selectedAppID })
    }

    var totalReclaimPotential: Int64 {
        state.apps.reduce(0) { $0 + $1.artifacts.reduce(0) { $0 + $1.sizeBytes } }
    }

    func loadApps() async {
        state.isLoading = true
        state.errorMessage = nil
        state.scanMessage = "Preparing scan..."
        state.scanProgress = nil

        do {
            let catalog = try await appCatalogService.fetchInstalledApps { [weak self] progress in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.state.scanMessage = progress.message
                    self.state.scanProgress = progress.fractionCompleted
                }
            }

            var enriched: [InstalledApp] = []
            for (index, app) in catalog.enumerated() {
                state.scanMessage = "Resolving support files for \(app.displayName)..."
                state.scanProgress = catalog.isEmpty ? nil : min(max(Double(index) / Double(catalog.count), 0), 1)

                var item = app
                item.artifacts = await artifactResolver.artifacts(for: app)
                enriched.append(item)

                state.scanProgress = catalog.isEmpty ? nil : min(max(Double(index + 1) / Double(catalog.count), 0), 1)
            }

            state.apps = enriched
            if selectedAppID == nil {
                selectedAppID = enriched.first?.id
            }

            if let infoProvider = appCatalogService as? AppCatalogFetchInfoProvider {
                let info = await infoProvider.latestFetchInfo()
                state.usedCachedResults = info.source == .cached
                state.lastScanAt = info.fetchedAt
                if info.source == .cached {
                    state.scanMessage = "Loaded from cache."
                }
            } else {
                state.usedCachedResults = false
                state.lastScanAt = Date()
            }

            applyFilters()
            if !state.usedCachedResults {
                state.scanMessage = "Scan complete."
            }
            state.scanProgress = 1
        } catch {
            state.errorMessage = error.localizedDescription
            state.apps = []
            state.filteredApps = []
            state.scanMessage = "Scan failed."
            state.scanProgress = nil
            state.usedCachedResults = false
        }

        state.isLoading = false
    }

    func refreshOrphans() async {
        let existing = Set(state.apps.map(\ .bundleID))
        orphanArtifacts = await artifactResolver.orphanArtifacts(existingBundleIDs: existing)
    }

    func createPlan(mode: CleanupMode) {
        guard let app = selectedApp else { return }
        uninstallState.selectedMode = mode
        uninstallState.plan = cleanupPlanner.makePlan(for: app, mode: mode)
        uninstallState.executionResult = nil
        uninstallState.errorMessage = nil
    }

    func executeUninstallPlan() async {
        guard let plan = uninstallState.plan else { return }
        uninstallState.isExecuting = true
        let result = await cleanupExecutor.execute(plan: plan)
        uninstallState.executionResult = result
        uninstallState.isExecuting = false

        if result.failures.isEmpty, let appID = selectedAppID {
            state.apps.removeAll(where: { $0.id == appID })
            selectedAppID = state.apps.first?.id
            applyFilters()
        }
    }

    func executeOrphanCleanup() async {
        guard !orphanArtifacts.isEmpty else { return }

        let fakeApp = InstalledApp(
            id: "orphans",
            displayName: "Orphaned Data",
            bundleID: "orphans",
            bundlePath: "/",
            executablePath: nil,
            lastUsedDate: nil,
            bundleSizeBytes: 0,
            artifacts: orphanArtifacts
        )

        let candidate = CleanupCandidate(app: fakeApp, mode: .removeEverything, selectedArtifacts: orphanArtifacts)
        uninstallState.plan = CleanupPlan(candidates: [candidate])
        uninstallState.isExecuting = true
        let result = await cleanupExecutor.execute(plan: uninstallState.plan!)
        uninstallState.executionResult = result
        uninstallState.isExecuting = false
        if result.failures.isEmpty {
            orphanArtifacts = []
        }
    }

    private func applyFilters() {
        var apps = state.apps

        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let term = searchText.lowercased()
            apps = apps.filter {
                $0.displayName.lowercased().contains(term) ||
                $0.bundleID.lowercased().contains(term)
            }
        }

        switch sortOrder {
        case .size:
            apps.sort(by: { $0.trueSizeBytes > $1.trueSizeBytes })
        case .name:
            apps.sort(by: { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending })
        case .lastUsed:
            apps.sort(by: { ($0.lastUsedDate ?? .distantPast) > ($1.lastUsedDate ?? .distantPast) })
        }

        state.filteredApps = apps
        if let selectedAppID, !apps.contains(where: { $0.id == selectedAppID }) {
            self.selectedAppID = apps.first?.id
        }
    }
}
