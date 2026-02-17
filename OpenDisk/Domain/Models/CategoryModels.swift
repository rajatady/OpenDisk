import Foundation

nonisolated enum SmartCategoryKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case applications
    case userData
    case caches
    case preferences
    case systemIntegration

    var id: String { rawValue }

    var title: String {
        switch self {
        case .applications:
            return "Applications"
        case .userData:
            return "User Data"
        case .caches:
            return "Caches"
        case .preferences:
            return "Preferences"
        case .systemIntegration:
            return "System Integration"
        }
    }

    var systemImage: String {
        switch self {
        case .applications:
            return "square.grid.2x2"
        case .userData:
            return "folder"
        case .caches:
            return "internaldrive"
        case .preferences:
            return "slider.horizontal.3"
        case .systemIntegration:
            return "gearshape.2"
        }
    }
}

nonisolated struct SmartCategory: Identifiable, Hashable, Codable, Sendable {
    let kind: SmartCategoryKind
    let totalBytes: Int64
    let itemCount: Int
    let safeCleanupBytes: Int64
    let reviewCleanupBytes: Int64
    let riskyCleanupBytes: Int64

    var id: SmartCategoryKind { kind }
}
