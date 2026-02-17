import Foundation

enum UserProfileKind: String, Codable, CaseIterable, Sendable {
    case iosDeveloper
    case webDeveloper
    case mlEngineer
    case designer
    case videoCreator
    case dataScientist
    case generalUser
}

struct ProfileEvidence: Hashable, Codable, Sendable {
    let reason: String
    let weight: Double
}

struct UserProfile: Hashable, Codable, Sendable {
    let kinds: [UserProfileKind]
    let confidence: Double
    let evidence: [ProfileEvidence]
}

struct FileMetadata: Hashable, Codable, Sendable {
    let path: String
    let sizeBytes: Int64
    let fileCount: Int
    let depth: Int
    let extensionName: String
}

struct SemanticCleanupUnit: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    let path: String
    let totalBytes: Int64
    let fileCount: Int
    let risk: SafetyLevel
    let reason: String
}

struct Recommendation: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    let detail: String
    let path: String?
    let impactScore: Double
    let confidenceScore: Double
    let riskScore: Double
    let reversible: Bool
}

enum AICapabilityStatus: Hashable, Codable, Sendable {
    case supported
    case unsupported(reason: String)

    var isSupported: Bool {
        switch self {
        case .supported:
            return true
        case .unsupported:
            return false
        }
    }
}
