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

    func load(apps: [InstalledApp], diskRoot: DiskNode?, usedCachedResults: Bool) {
        state.isLoading = true
        state.errorMessage = nil

        let largeItems = Self.buildLargeItems(from: apps, diskRoot: diskRoot)
        let duplicateGroups = Self.buildDuplicateGroups(from: apps, diskRoot: diskRoot)

        state.largeItems = largeItems
        state.duplicateGroups = duplicateGroups
        state.usedCachedResults = usedCachedResults
        state.isLoading = false
    }

    var potentialDuplicateReclaim: Int64 {
        state.duplicateGroups.reduce(0) { $0 + max(0, $1.totalBytes - ($1.duplicates.first?.sizeBytes ?? 0)) }
    }

    nonisolated deinit {}

    private static func buildLargeItems(from apps: [InstalledApp], diskRoot: DiskNode?) -> [LargeItem] {
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

        if let diskRoot {
            for node in flattenDiskNodes(root: diskRoot, maxDepth: 5, limit: 1_200) where node.sizeBytes > 5_000_000 {
                items.append(
                    LargeItem(
                        id: "disk:\(node.path)",
                        title: node.name.isEmpty ? "/" : node.name,
                        path: node.path,
                        sizeBytes: node.sizeBytes,
                        isDirectory: node.isDirectory,
                        sourceBundleID: nil
                    )
                )
            }
        }

        return items
            .sorted(by: { $0.sizeBytes > $1.sizeBytes })
            .prefix(200)
            .map { $0 }
    }

    private static func buildDuplicateGroups(from apps: [InstalledApp], diskRoot: DiskNode?) -> [DuplicateGroup] {
        let candidates: [DuplicateCandidate] = apps.flatMap { app in
            app.artifacts.filter { !$0.isDirectory }.map {
                DuplicateCandidate(
                    id: "\($0.path)|\(app.bundleID)",
                    path: $0.path,
                    sizeBytes: $0.sizeBytes,
                    sourceBundleID: app.bundleID
                )
            }
        }

        var all = candidates

        if let diskRoot {
            let diskCandidates = flattenDiskNodes(root: diskRoot, maxDepth: 6, limit: 2_000)
                .filter { !$0.isDirectory && $0.sizeBytes > 5_000_000 }
                .map {
                    DuplicateCandidate(
                        id: "disk:\($0.path)",
                        path: $0.path,
                        sizeBytes: $0.sizeBytes,
                        sourceBundleID: nil
                    )
                }
            all.append(contentsOf: diskCandidates)
        }

        let grouped = Dictionary(grouping: all) { candidate in
            let name = normalizedName(for: candidate.path)
            return "\(name)|\(candidate.sizeBytes)"
        }

        return grouped
            .filter { $0.value.count > 1 }
            .map { key, values in
                let name = key.split(separator: "|").first.map(String.init) ?? "duplicate"
                let sortedValues = values.sorted(by: { $0.path < $1.path })
                let totalBytes = sortedValues.reduce(0) { $0 + $1.sizeBytes }
                return DuplicateGroup(
                    id: key,
                    name: name,
                    totalBytes: totalBytes,
                    duplicates: sortedValues
                )
            }
            .filter { group in
                group.duplicates.count >= 2 &&
                (
                    group.totalBytes > 20_000_000 ||
                    group.duplicates.contains(where: { $0.sourceBundleID != nil })
                )
            }
            .sorted(by: { $0.totalBytes > $1.totalBytes })
            .prefix(120)
            .map { $0 }
    }

    private static func flattenDiskNodes(root: DiskNode, maxDepth: Int, limit: Int) -> [DiskNode] {
        var result: [DiskNode] = []
        var queue: [(DiskNode, Int)] = [(root, 0)]
        var cursor = 0

        while cursor < queue.count, result.count < limit {
            let (node, depth) = queue[cursor]
            cursor += 1
            if depth > 0 {
                result.append(node)
            }

            guard depth < maxDepth else {
                continue
            }

            for child in node.children {
                queue.append((child, depth + 1))
            }
        }

        return result
    }

    private static func normalizedName(for path: String) -> String {
        let base = URL(fileURLWithPath: path)
            .deletingPathExtension()
            .lastPathComponent
            .lowercased()
        let reduced = base.replacingOccurrences(
            of: #"(?:[_\-\s](?:v)?\d+|[_\-\s][0-9a-f]{6,})+$"#,
            with: "",
            options: .regularExpression
        )
        return reduced.isEmpty ? base : reduced
    }
}
