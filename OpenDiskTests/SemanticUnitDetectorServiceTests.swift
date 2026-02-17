import XCTest
@testable import OpenDisk

@MainActor
final class SemanticUnitDetectorServiceTests: XCTestCase {
    func testDetectsCheckpointFolderAsSemanticUnit() async throws {
        let tempRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let checkpoints = tempRoot.appendingPathComponent("project/checkpoints", isDirectory: true)
        try FileManager.default.createDirectory(at: checkpoints, withIntermediateDirectories: true)

        let fileURL = checkpoints.appendingPathComponent("weights.ckpt")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data())
        let handle = try FileHandle(forWritingTo: fileURL)
        try handle.truncate(atOffset: 24_000_000)
        try handle.close()

        let detector = SemanticUnitDetectorService(sizeCalculator: FileSystemSizeCalculator())

        let units = await detector.detectUnits(in: tempRoot)

        XCTAssertTrue(units.contains(where: { $0.path.contains("checkpoints") }))

        try? FileManager.default.removeItem(at: tempRoot)
    }
}
