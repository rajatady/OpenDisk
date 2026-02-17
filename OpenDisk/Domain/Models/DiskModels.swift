import Foundation

struct DiskNode: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let path: String
    let sizeBytes: Int64
    let isDirectory: Bool
    let children: [DiskNode]
}
