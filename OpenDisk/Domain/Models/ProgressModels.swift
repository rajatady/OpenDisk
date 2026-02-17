import Foundation

struct AppScanProgress: Sendable {
    let message: String
    let completed: Int
    let total: Int

    var fractionCompleted: Double? {
        guard total > 0 else { return nil }
        return min(max(Double(completed) / Double(total), 0), 1)
    }
}

enum CacheSource: String, Codable, Sendable {
    case live
    case cached
}

struct AppCatalogFetchInfo: Hashable, Codable, Sendable {
    let source: CacheSource
    let fetchedAt: Date
}

struct RecommendationsCacheEntry: Hashable, Codable, Sendable {
    let key: String
    let createdAt: Date
    let profile: UserProfile
    let recommendations: [Recommendation]
}

struct StorageMapCacheEntry: Hashable, Codable, Sendable {
    let key: String
    let createdAt: Date
    let root: DiskNode
}
