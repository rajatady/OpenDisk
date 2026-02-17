import Foundation

nonisolated struct LargeItem: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    let path: String
    let sizeBytes: Int64
    let isDirectory: Bool
    let sourceBundleID: String?
}

nonisolated struct DuplicateCandidate: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let path: String
    let sizeBytes: Int64
    let sourceBundleID: String?
}

nonisolated struct DuplicateGroup: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let totalBytes: Int64
    let duplicates: [DuplicateCandidate]
}
