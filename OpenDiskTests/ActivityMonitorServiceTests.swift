import XCTest
@testable import OpenDisk

final class ActivityMonitorServiceTests: XCTestCase {
    func testActivitySamplesPersistAndRespectLimit() async {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("OpenDiskTests-Activity-\(UUID().uuidString)", isDirectory: true)
        let storageURL = root.appendingPathComponent("activity.json")

        let service = ActivityMonitorService(fileManager: fileManager, storageURL: storageURL, maxItems: 3)

        await service.record(sample: ActivitySample(id: UUID(), capturedAt: Date().addingTimeInterval(-3), appCount: 5, recommendationCount: 3, reclaimBytes: 100, scanDurationSeconds: 1.0, usedCachedCatalog: false))
        await service.record(sample: ActivitySample(id: UUID(), capturedAt: Date().addingTimeInterval(-2), appCount: 6, recommendationCount: 4, reclaimBytes: 200, scanDurationSeconds: 1.2, usedCachedCatalog: true))
        await service.record(sample: ActivitySample(id: UUID(), capturedAt: Date().addingTimeInterval(-1), appCount: 7, recommendationCount: 5, reclaimBytes: 300, scanDurationSeconds: 1.4, usedCachedCatalog: false))
        await service.record(sample: ActivitySample(id: UUID(), capturedAt: Date(), appCount: 8, recommendationCount: 6, reclaimBytes: 400, scanDurationSeconds: 1.6, usedCachedCatalog: true))

        let limited = await service.samples(limit: 2)
        XCTAssertEqual(limited.count, 2)
        XCTAssertEqual(limited.first?.reclaimBytes, 300)
        XCTAssertEqual(limited.last?.reclaimBytes, 400)

        let reloaded = ActivityMonitorService(fileManager: fileManager, storageURL: storageURL, maxItems: 3)
        let persisted = await reloaded.samples(limit: nil)
        XCTAssertEqual(persisted.count, 3)
        XCTAssertEqual(persisted.first?.reclaimBytes, 200)

        try? fileManager.removeItem(at: root)
    }
}
