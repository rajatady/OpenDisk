import Foundation

struct CleanupExecutorService: CleanupExecutorProtocol {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func execute(plan: CleanupPlan) async -> CleanupExecutionResult {
        var reclaimed: Int64 = 0
        var removed: [String] = []
        var failures: [CleanupFailure] = []

        let uniqueArtifacts = Dictionary(grouping: plan.candidates.flatMap(\.selectedArtifacts), by: \.path)
            .compactMap { $0.value.first }

        for artifact in uniqueArtifacts {
            let url = artifact.url
            guard fileManager.fileExists(atPath: url.path) else { continue }

            do {
                var trashed: NSURL?
                try fileManager.trashItem(at: url, resultingItemURL: &trashed)
                reclaimed += artifact.sizeBytes
                removed.append(url.path)
            } catch {
                failures.append(CleanupFailure(path: url.path, reason: error.localizedDescription))
            }
        }

        return CleanupExecutionResult(reclaimedBytes: reclaimed, removedPaths: removed, failures: failures)
    }
}
