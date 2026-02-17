import Foundation

enum SafetyLevel: String, Codable, CaseIterable, Sendable {
    case safe
    case review
    case risky
}

enum ArtifactGroupKind: String, Codable, CaseIterable, Sendable {
    case appBundle
    case userData
    case cache
    case preferences
    case systemIntegration
}

struct AssociatedArtifact: Identifiable, Hashable, Codable, Sendable {
    let path: String
    let groupKind: ArtifactGroupKind
    let safetyLevel: SafetyLevel
    let sizeBytes: Int64
    let isDirectory: Bool

    var id: String { path }

    var url: URL {
        URL(fileURLWithPath: path)
    }
}

struct ArtifactGroup: Identifiable, Hashable, Codable, Sendable {
    let kind: ArtifactGroupKind
    var artifacts: [AssociatedArtifact]

    var id: ArtifactGroupKind { kind }

    var totalBytes: Int64 {
        artifacts.reduce(0) { $0 + $1.sizeBytes }
    }
}

struct InstalledApp: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let displayName: String
    let bundleID: String
    let bundlePath: String
    let executablePath: String?
    let lastUsedDate: Date?
    var bundleSizeBytes: Int64
    var artifacts: [AssociatedArtifact]

    init(
        id: String,
        displayName: String,
        bundleID: String,
        bundlePath: String,
        executablePath: String?,
        lastUsedDate: Date?,
        bundleSizeBytes: Int64,
        artifacts: [AssociatedArtifact] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.bundleID = bundleID
        self.bundlePath = bundlePath
        self.executablePath = executablePath
        self.lastUsedDate = lastUsedDate
        self.bundleSizeBytes = bundleSizeBytes
        self.artifacts = artifacts
    }

    var bundleURL: URL {
        URL(fileURLWithPath: bundlePath)
    }

    var trueSizeBytes: Int64 {
        bundleSizeBytes + artifacts.reduce(0) { $0 + $1.sizeBytes }
    }

    var groupedArtifacts: [ArtifactGroup] {
        Dictionary(grouping: artifacts, by: \.groupKind)
            .map { ArtifactGroup(kind: $0.key, artifacts: $0.value.sorted(by: { $0.sizeBytes > $1.sizeBytes })) }
            .sorted(by: { $0.totalBytes > $1.totalBytes })
    }
}
