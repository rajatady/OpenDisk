import XCTest
@testable import OpenDisk

final class RecommendationRankerServiceTests: XCTestCase {
    func testRankerPrioritizesLargerImpactRecommendations() {
        let ranker = RecommendationRankerService()

        let profile = UserProfile(kinds: [.webDeveloper], confidence: 0.85, evidence: [])
        let apps = [
            InstalledApp(id: "small", displayName: "Small", bundleID: "com.example.small", bundlePath: "/Applications/Small.app", executablePath: nil, lastUsedDate: nil, bundleSizeBytes: 100_000_000, artifacts: []),
            InstalledApp(id: "big", displayName: "Big", bundleID: "com.example.big", bundlePath: "/Applications/Big.app", executablePath: nil, lastUsedDate: nil, bundleSizeBytes: 12_000_000_000, artifacts: [])
        ]
        let units = [
            SemanticCleanupUnit(id: "u1", title: "node_modules", path: "/tmp/node_modules", totalBytes: 4_000_000_000, fileCount: 10000, risk: .review, reason: "Dependency folder")
        ]

        let recommendations = ranker.rank(profile: profile, apps: apps, semanticUnits: units)

        XCTAssertGreaterThanOrEqual(recommendations.count, 2)
        XCTAssertEqual(recommendations.first?.title.contains("Big") ?? false, true)
    }
}
