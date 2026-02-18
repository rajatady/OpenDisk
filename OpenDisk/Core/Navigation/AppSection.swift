import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case appManager
    case recommendations
    case storageMap
    case smartCategories
    case duplicates
    case timeline

    var id: String { rawValue }

    // Strict production mode: only ship sections with executable cleanup actions.
    static let productionReadySections: [AppSection] = [
        .appManager,
        .smartCategories
    ]

    var title: String {
        switch self {
        case .appManager:
            return "App Manager"
        case .recommendations:
            return "Smart Cleanup"
        case .storageMap:
            return "Storage Map"
        case .smartCategories:
            return "Categories"
        case .duplicates:
            return "Duplicates"
        case .timeline:
            return "Activity"
        }
    }

    var systemImage: String {
        switch self {
        case .appManager:
            return "square.grid.2x2"
        case .recommendations:
            return "sparkles"
        case .storageMap:
            return "circle.grid.cross"
        case .smartCategories:
            return "square.stack.3d.up"
        case .duplicates:
            return "doc.on.doc"
        case .timeline:
            return "waveform.path.ecg.rectangle"
        }
    }
}
