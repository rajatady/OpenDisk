import Foundation
import Combine

@MainActor
final class ActivityMonitorViewModel: ObservableObject {
    @Published private(set) var state = ActivityMonitorViewState(
        samples: [],
        snapshots: [],
        summary: nil,
        growthProjection: nil,
        isLoading: false,
        errorMessage: nil
    )

    private let activityService: ActivityMonitorServiceProtocol
    private let timelineStore: TimelineStoreProtocol

    convenience init(container: AppContainer) {
        self.init(
            activityService: container.activityMonitor,
            timelineStore: container.timelineStore
        )
    }

    init(
        activityService: ActivityMonitorServiceProtocol,
        timelineStore: TimelineStoreProtocol
    ) {
        self.activityService = activityService
        self.timelineStore = timelineStore
    }

    func refresh() async {
        state.isLoading = true
        state.errorMessage = nil

        let samples = await activityService.samples(limit: 120)
        let snapshots = await timelineStore.snapshots()
        state.samples = samples
        state.snapshots = snapshots
        state.summary = Self.makeSummary(from: samples)
        state.growthProjection = Self.makeProjection(from: snapshots)
        state.isLoading = false
    }

    func recordSession(
        appCount: Int,
        recommendationCount: Int,
        reclaimBytes: Int64,
        scanDurationSeconds: Double,
        usedCachedCatalog: Bool
    ) async {
        let sample = ActivitySample(
            id: UUID(),
            capturedAt: Date(),
            appCount: appCount,
            recommendationCount: recommendationCount,
            reclaimBytes: reclaimBytes,
            scanDurationSeconds: scanDurationSeconds,
            usedCachedCatalog: usedCachedCatalog
        )

        await activityService.record(sample: sample)
        await refresh()
    }

    func recordSnapshot(
        usedBytes: Int64,
        freeBytes: Int64,
        capturedAt: Date = Date(),
        refreshAfterSave: Bool = true
    ) async {
        let snapshot = DiskSnapshot(
            id: UUID(),
            capturedAt: capturedAt,
            usedBytes: max(0, usedBytes),
            freeBytes: max(0, freeBytes)
        )
        await timelineStore.save(snapshot: snapshot)
        if refreshAfterSave {
            await refresh()
        }
    }

    private static func makeSummary(from samples: [ActivitySample]) -> ActivitySummary? {
        guard !samples.isEmpty else {
            return nil
        }

        let durationTotal = samples.reduce(0.0) { $0 + $1.scanDurationSeconds }
        let cachedCount = samples.filter(\.usedCachedCatalog).count
        let peakReclaim = samples.map(\.reclaimBytes).max() ?? 0
        let latestReclaim = samples.last?.reclaimBytes ?? 0

        return ActivitySummary(
            averageScanDurationSeconds: durationTotal / Double(samples.count),
            cacheHitRate: Double(cachedCount) / Double(samples.count),
            peakReclaimBytes: peakReclaim,
            latestReclaimBytes: latestReclaim
        )
    }

    private static func makeProjection(from snapshots: [DiskSnapshot]) -> GrowthProjection? {
        let ordered = snapshots.sorted(by: { $0.capturedAt < $1.capturedAt })
        guard ordered.count >= 2, let first = ordered.first, let last = ordered.last else {
            return nil
        }

        let elapsedSeconds = last.capturedAt.timeIntervalSince(first.capturedAt)
        guard elapsedSeconds > 0 else {
            return nil
        }

        let growthBytes = last.usedBytes - first.usedBytes
        guard growthBytes > 0 else {
            return nil
        }

        let elapsedDays = elapsedSeconds / 86_400
        guard elapsedDays > 0 else {
            return nil
        }

        let averageDailyGrowth = Int64((Double(growthBytes) / elapsedDays).rounded())
        guard averageDailyGrowth > 0 else {
            return nil
        }

        let remaining = max(0, last.freeBytes)
        let daysUntilFull = max(1, Int(ceil(Double(remaining) / Double(averageDailyGrowth))))

        return GrowthProjection(
            daysUntilFull: daysUntilFull,
            averageDailyGrowthBytes: averageDailyGrowth
        )
    }
}
