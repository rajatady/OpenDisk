import XCTest
@testable import OpenDisk

final class TimelineStoreTests: XCTestCase {
    func testTimelineStorePersistsAndRespectsLimit() async {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("OpenDiskTests-Timeline-\(UUID().uuidString)", isDirectory: true)
        let storageURL = root.appendingPathComponent("timeline.json")
        let base = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TimelineStore(
            fileManager: fileManager,
            storageURL: storageURL,
            maxItems: 3
        )

        await store.save(snapshot: DiskSnapshot(id: UUID(), capturedAt: base.addingTimeInterval(-4), usedBytes: 100, freeBytes: 900))
        await store.save(snapshot: DiskSnapshot(id: UUID(), capturedAt: base.addingTimeInterval(-3), usedBytes: 200, freeBytes: 800))
        await store.save(snapshot: DiskSnapshot(id: UUID(), capturedAt: base.addingTimeInterval(-2), usedBytes: 300, freeBytes: 700))
        await store.save(snapshot: DiskSnapshot(id: UUID(), capturedAt: base.addingTimeInterval(-1), usedBytes: 400, freeBytes: 600))

        let limited = await store.snapshots()
        XCTAssertEqual(limited.count, 3)
        XCTAssertEqual(limited.first?.usedBytes, 200)
        XCTAssertEqual(limited.last?.usedBytes, 400)

        let reloaded = TimelineStore(
            fileManager: fileManager,
            storageURL: storageURL,
            maxItems: 3
        )
        let persisted = await reloaded.snapshots()
        XCTAssertEqual(persisted.count, 3)
        XCTAssertEqual(persisted.first?.usedBytes, 200)
        XCTAssertEqual(persisted.last?.usedBytes, 400)

        try? fileManager.removeItem(at: root)
    }
}
