import Foundation

struct CleanupPlannerService: CleanupPlannerProtocol {
    func makePlan(for app: InstalledApp, mode: CleanupMode) -> CleanupPlan {
        let selected: [AssociatedArtifact]
        switch mode {
        case .removeEverything:
            selected = app.artifacts
        case .keepUserData:
            selected = app.artifacts.filter { $0.groupKind != .userData }
        }

        let candidate = CleanupCandidate(app: app, mode: mode, selectedArtifacts: selected)
        return CleanupPlan(candidates: [candidate])
    }
}
