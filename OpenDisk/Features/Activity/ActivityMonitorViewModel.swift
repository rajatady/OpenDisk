import Foundation
import Combine

@MainActor
final class ActivityMonitorViewModel: ObservableObject {
    @Published private(set) var state = ActivityMonitorViewState(
        samples: [],
        summary: nil,
        isLoading: false,
        errorMessage: nil
    )

    private let activityService: ActivityMonitorServiceProtocol

    init(container: AppContainer) {
        self.activityService = container.activityMonitor
    }

    func refresh() async {
        state.isLoading = true
        state.errorMessage = nil

        let samples = await activityService.samples(limit: 120)
        state.samples = samples
        state.summary = makeSummary(from: samples)
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

    private func makeSummary(from samples: [ActivitySample]) -> ActivitySummary? {
        guard !samples.isEmpty else {
            return nil
        }

        let durationTotal = samples.reduce(0.0) { $0 + $1.scanDurationSeconds }
        let cachedCount = samples.filter(\ .usedCachedCatalog).count
        let peakReclaim = samples.map(\ .reclaimBytes).max() ?? 0
        let latestReclaim = samples.last?.reclaimBytes ?? 0

        return ActivitySummary(
            averageScanDurationSeconds: durationTotal / Double(samples.count),
            cacheHitRate: Double(cachedCount) / Double(samples.count),
            peakReclaimBytes: peakReclaim,
            latestReclaimBytes: latestReclaim
        )
    }
}
