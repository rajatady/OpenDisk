import XCTest
@testable import OpenDisk

@MainActor
final class ActivityMonitorViewModelTests: XCTestCase {
    func testRefreshBuildsSummaryAndGrowthProjection() async {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let activityService = MemoryActivityMonitorService(
            samples: [
                ActivitySample(
                    id: UUID(),
                    capturedAt: base.addingTimeInterval(-3600),
                    appCount: 12,
                    recommendationCount: 4,
                    reclaimBytes: 2_000,
                    scanDurationSeconds: 6.0,
                    usedCachedCatalog: false
                ),
                ActivitySample(
                    id: UUID(),
                    capturedAt: base,
                    appCount: 15,
                    recommendationCount: 5,
                    reclaimBytes: 4_000,
                    scanDurationSeconds: 4.0,
                    usedCachedCatalog: true
                )
            ]
        )
        let timelineStore = MemoryTimelineStore(
            snapshots: [
                DiskSnapshot(
                    id: UUID(),
                    capturedAt: base.addingTimeInterval(-172_800),
                    usedBytes: 1_000,
                    freeBytes: 9_000
                ),
                DiskSnapshot(
                    id: UUID(),
                    capturedAt: base,
                    usedBytes: 3_000,
                    freeBytes: 7_000
                )
            ]
        )
        let viewModel = ActivityMonitorViewModel(
            activityService: activityService,
            timelineStore: timelineStore
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state.samples.count, 2)
        XCTAssertEqual(viewModel.state.snapshots.count, 2)
        XCTAssertEqual(viewModel.state.summary?.peakReclaimBytes, 4_000)
        XCTAssertEqual(viewModel.state.summary?.cacheHitRate ?? 0, 0.5, accuracy: 0.0001)
        XCTAssertEqual(viewModel.state.summary?.averageScanDurationSeconds ?? 0, 5.0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.state.growthProjection?.averageDailyGrowthBytes, 1_000)
        XCTAssertEqual(viewModel.state.growthProjection?.daysUntilFull, 7)
    }

    func testRecordSessionAndSnapshotUpdateState() async {
        let activityService = MemoryActivityMonitorService(samples: [])
        let timelineStore = MemoryTimelineStore(snapshots: [])
        let viewModel = ActivityMonitorViewModel(
            activityService: activityService,
            timelineStore: timelineStore
        )

        await viewModel.recordSnapshot(
            usedBytes: 12_000,
            freeBytes: 8_000,
            capturedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        await viewModel.recordSession(
            appCount: 21,
            recommendationCount: 7,
            reclaimBytes: 5_000,
            scanDurationSeconds: 3.5,
            usedCachedCatalog: true
        )

        XCTAssertEqual(viewModel.state.snapshots.count, 1)
        XCTAssertEqual(viewModel.state.samples.count, 1)
        XCTAssertEqual(viewModel.state.samples.first?.reclaimBytes, 5_000)
        XCTAssertEqual(viewModel.state.summary?.latestReclaimBytes, 5_000)
    }
}

actor MemoryActivityMonitorService: ActivityMonitorServiceProtocol {
    private var stored: [ActivitySample]

    init(samples: [ActivitySample]) {
        self.stored = samples
    }

    func record(sample: ActivitySample) async {
        stored.append(sample)
        stored.sort(by: { $0.capturedAt < $1.capturedAt })
    }

    func samples(limit: Int?) async -> [ActivitySample] {
        guard let limit, limit > 0 else {
            return stored
        }
        return Array(stored.suffix(limit))
    }
}

actor MemoryTimelineStore: TimelineStoreProtocol {
    private var stored: [DiskSnapshot]

    init(snapshots: [DiskSnapshot]) {
        self.stored = snapshots
    }

    func save(snapshot: DiskSnapshot) async {
        stored.append(snapshot)
        stored.sort(by: { $0.capturedAt < $1.capturedAt })
    }

    func snapshots() async -> [DiskSnapshot] {
        stored
    }
}
