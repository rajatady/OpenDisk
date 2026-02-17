import Foundation

enum CleanupMode: String, Codable, CaseIterable, Sendable {
    case removeEverything
    case keepUserData
}

struct CleanupCandidate: Hashable, Codable, Sendable {
    let app: InstalledApp
    let mode: CleanupMode
    let selectedArtifacts: [AssociatedArtifact]
}

struct CleanupPlan: Hashable, Codable, Sendable {
    let candidates: [CleanupCandidate]

    var totalBytes: Int64 {
        candidates.flatMap(\.selectedArtifacts).reduce(0) { $0 + $1.sizeBytes }
    }

    var fileCount: Int {
        candidates.flatMap(\.selectedArtifacts).count
    }
}

struct CleanupFailure: Hashable, Codable, Sendable {
    let path: String
    let reason: String
}

struct CleanupExecutionResult: Hashable, Codable, Sendable {
    let reclaimedBytes: Int64
    let removedPaths: [String]
    let failures: [CleanupFailure]

    var isSuccessful: Bool {
        failures.isEmpty
    }
}
