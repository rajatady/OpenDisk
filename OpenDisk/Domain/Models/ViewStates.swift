import Foundation

enum PermissionStatus: String, Codable, Sendable {
    case notDetermined
    case denied
    case authorized
}

enum ScanScope: String, Codable, CaseIterable, Identifiable, Sendable {
    case home
    case applications
    case fullDisk

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            return "Home Folder"
        case .applications:
            return "Applications"
        case .fullDisk:
            return "Full Disk"
        }
    }

    var description: String {
        switch self {
        case .home:
            return "Fast and focused. Best for quick wins."
        case .applications:
            return "Prioritizes app uninstall and support files."
        case .fullDisk:
            return "Deep scan across all reachable paths."
        }
    }
}

struct OnboardingViewState: Sendable {
    var currentStep: Int
    var permissionStatus: PermissionStatus
    var aiStatus: AICapabilityStatus
    var selectedScope: ScanScope
    var quickScanSummary: String
    var quickScanMessage: String
    var quickScanProgress: Double?
    var isRunningQuickScan: Bool
    var canFinish: Bool
}

struct PermissionsViewState: Sendable {
    let status: PermissionStatus
    let details: String
}

struct AppManagerViewState: Sendable {
    var apps: [InstalledApp]
    var filteredApps: [InstalledApp]
    var isLoading: Bool
    var scanMessage: String
    var scanProgress: Double?
    var usedCachedResults: Bool
    var lastScanAt: Date?
    var errorMessage: String?
}

struct UninstallFlowState: Sendable {
    var selectedMode: CleanupMode
    var plan: CleanupPlan?
    var executionResult: CleanupExecutionResult?
    var isExecuting: Bool
    var errorMessage: String?
}

struct RecommendationsViewState: Sendable {
    var profile: UserProfile?
    var recommendations: [Recommendation]
    var isLoading: Bool
    var usedCachedResults: Bool
    var errorMessage: String?
}

struct StorageMapViewState: Sendable {
    var root: DiskNode?
    var isLoading: Bool
    var scanMessage: String
    var scanProgress: Double?
    var usedCachedResults: Bool
    var lastScanAt: Date?
    var errorMessage: String?
}

struct SmartCategoriesViewState: Sendable {
    var categories: [SmartCategory]
    var isLoading: Bool
    var usedCachedResults: Bool
    var errorMessage: String?
}

struct DuplicatesViewState: Sendable {
    var largeItems: [LargeItem]
    var duplicateGroups: [DuplicateGroup]
    var isLoading: Bool
    var usedCachedResults: Bool
    var errorMessage: String?
}

struct ActivityMonitorViewState: Sendable {
    var samples: [ActivitySample]
    var summary: ActivitySummary?
    var isLoading: Bool
    var errorMessage: String?
}
