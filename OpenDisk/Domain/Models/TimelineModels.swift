import Foundation

struct DiskSnapshot: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let capturedAt: Date
    let usedBytes: Int64
    let freeBytes: Int64
}

struct GrowthProjection: Hashable, Codable, Sendable {
    let daysUntilFull: Int
    let averageDailyGrowthBytes: Int64
}

struct AutomationRule: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let title: String
    let isEnabled: Bool
    let thresholdBytes: Int64
    let target: String
}

struct ActivitySample: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let capturedAt: Date
    let appCount: Int
    let recommendationCount: Int
    let reclaimBytes: Int64
    let scanDurationSeconds: Double
    let usedCachedCatalog: Bool
}

struct ActivitySummary: Hashable, Sendable {
    let averageScanDurationSeconds: Double
    let cacheHitRate: Double
    let peakReclaimBytes: Int64
    let latestReclaimBytes: Int64
}
