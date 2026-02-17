import Foundation
import Combine

@MainActor
final class DuplicatesViewModel: ObservableObject {
    @Published private(set) var state = DuplicatesViewState(
        largeItems: [],
        duplicateGroups: [],
        isLoading: false,
        usedCachedResults: false,
        errorMessage: nil
    )

    func load(apps: [InstalledApp], usedCachedResults: Bool) {
        state.isLoading = true
        state.errorMessage = nil

        let largeItems = Self.buildLargeItems(from: apps)
        let duplicateGroups = Self.buildDuplicateGroups(from: apps)

        state.largeItems = largeItems
        state.duplicateGroups = duplicateGroups
        state.usedCachedResults = usedCachedResults
        state.isLoading = false
    }

    var potentialDuplicateReclaim: Int64 {
        state.duplicateGroups.reduce(0) { $0 + max(0, $1.totalBytes - ($1.duplicates.first?.sizeBytes ?? 0)) }
    }

    nonisolated deinit {}

    private static func buildLargeItems(from apps: [InstalledApp]) -> [LargeItem] {
        var items: [LargeItem] = apps.map {
            LargeItem(
                id: "bundle:\($0.id)",
                title: $0.displayName,
                path: $0.bundlePath,
                sizeBytes: $0.bundleSizeBytes,
                isDirectory: true,
                sourceBundleID: $0.bundleID
            )
        }

        for app in apps {
            for artifact in app.artifacts {
                items.append(
                    LargeItem(
                        id: "artifact:\(artifact.path)|\(app.bundleID)",
                        title: URL(fileURLWithPath: artifact.path).lastPathComponent,
                        path: artifact.path,
                        sizeBytes: artifact.sizeBytes,
                        isDirectory: artifact.isDirectory,
                        sourceBundleID: app.bundleID
                    )
                )
            }
        }

        return items
            .sorted(by: { $0.sizeBytes > $1.sizeBytes })
            .prefix(20)
            .map { $0 }
    }

    private static func buildDuplicateGroups(from apps: [InstalledApp]) -> [DuplicateGroup] {
        let candidates: [DuplicateCandidate] = apps.flatMap { app in
            app.artifacts.map {
                DuplicateCandidate(
                    id: "\($0.path)|\(app.bundleID)",
                    path: $0.path,
                    sizeBytes: $0.sizeBytes,
                    sourceBundleID: app.bundleID
                )
            }
        }

        let grouped = Dictionary(grouping: candidates) { candidate in
            let name = URL(fileURLWithPath: candidate.path).lastPathComponent.lowercased()
            return "\(name)|\(candidate.sizeBytes)"
        }

        return grouped
            .filter { $0.value.count > 1 }
            .map { key, values in
                let name = key.split(separator: "|").first.map(String.init) ?? "duplicate"
                let totalBytes = values.reduce(0) { $0 + $1.sizeBytes }
                return DuplicateGroup(
                    id: key,
                    name: name,
                    totalBytes: totalBytes,
                    duplicates: values.sorted(by: { $0.path < $1.path })
                )
            }
            .sorted(by: { $0.totalBytes > $1.totalBytes })
            .prefix(20)
            .map { $0 }
    }
}
