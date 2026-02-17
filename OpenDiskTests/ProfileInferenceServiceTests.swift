import XCTest
@testable import OpenDisk

@MainActor
final class ProfileInferenceServiceTests: XCTestCase {
    func testInferenceDetectsDeveloperAndMLSignals() async {
        let service = ProfileInferenceService(useFoundationModel: false)

        let apps = [
            InstalledApp(id: "1", displayName: "Xcode", bundleID: "com.apple.dt.Xcode", bundlePath: "/Applications/Xcode.app", executablePath: nil, lastUsedDate: nil, bundleSizeBytes: 0),
            InstalledApp(id: "2", displayName: "JupyterLab", bundleID: "org.jupyter", bundlePath: "/Applications/Jupyter.app", executablePath: nil, lastUsedDate: nil, bundleSizeBytes: 0)
        ]

        let profile = await service.inferProfile(apps: apps, metadata: [
            FileMetadata(path: "/tmp/checkpoints/model.ckpt", sizeBytes: 1200, fileCount: 1, depth: 3, extensionName: "ckpt")
        ])

        XCTAssertFalse(profile.kinds.isEmpty)
        XCTAssertTrue(profile.kinds.contains(.iosDeveloper) || profile.kinds.contains(.mlEngineer))
        XCTAssertGreaterThan(profile.confidence, 0.5)
    }

    func testInferenceFallsBackToGeneralUser() async {
        let service = ProfileInferenceService(useFoundationModel: false)

        let profile = await service.inferProfile(apps: [], metadata: [])

        XCTAssertEqual(profile.kinds, [.generalUser])
    }
}
