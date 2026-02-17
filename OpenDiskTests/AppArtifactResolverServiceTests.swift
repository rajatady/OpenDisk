import XCTest
@testable import OpenDisk

@MainActor
final class AppArtifactResolverServiceTests: XCTestCase {
    func testResolverFindsKnownArtifactsForBundleID() async throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cachePath = home.appendingPathComponent("Library/Caches/com.example.tool")
        let prefsPath = home.appendingPathComponent("Library/Preferences/com.example.tool.plist")
        let appPath = home.appendingPathComponent("Applications/Tool.app")

        try FileManager.default.createDirectory(at: cachePath, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: prefsPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: appPath, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: prefsPath.path, contents: Data([1, 2, 3]))

        let cacheFile = cachePath.appendingPathComponent("blob.data")
        FileManager.default.createFile(atPath: cacheFile.path, contents: Data(repeating: 1, count: 1024))

        let app = InstalledApp(
            id: "app",
            displayName: "Tool",
            bundleID: "com.example.tool",
            bundlePath: appPath.path,
            executablePath: nil,
            lastUsedDate: nil,
            bundleSizeBytes: 0
        )

        let resolver = AppArtifactResolverService(
            sizeCalculator: FileSystemSizeCalculator(),
            userHome: home
        )

        let artifacts = await resolver.artifacts(for: app)
        let artifactPaths = artifacts.map(\.path).joined(separator: "\n")

        XCTAssertTrue(
            artifacts.contains(where: { $0.path.contains("Caches/com.example.tool") }),
            "Expected cache artifact. Found:\n\(artifactPaths)"
        )
        XCTAssertTrue(
            artifacts.contains(where: { $0.path.contains("Preferences/com.example.tool.plist") }),
            "Expected preferences artifact. Found:\n\(artifactPaths)"
        )

        try? FileManager.default.removeItem(at: home)
    }
}
