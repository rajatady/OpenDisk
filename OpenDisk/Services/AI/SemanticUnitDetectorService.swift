import Foundation

struct SemanticUnitDetectorService: SemanticUnitDetectorProtocol {
    private let fileManager: FileManager
    private let sizeCalculator: FileSystemSizeCalculator

    init(fileManager: FileManager = .default, sizeCalculator: FileSystemSizeCalculator) {
        self.fileManager = fileManager
        self.sizeCalculator = sizeCalculator
    }

    func detectUnits(in rootURL: URL) async -> [SemanticCleanupUnit] {
        let patterns: [String: String] = [
            "checkpoints": "Training checkpoints can grow quickly.",
            "node_modules": "Dependency folder is often reproducible.",
            ".next": "Build cache for Next.js projects.",
            ".build": "Build output cache folder.",
            "deriveddata": "Xcode derived data can be safely regenerated.",
            "dist": "Build artifacts folder."
        ]

        guard fileManager.fileExists(atPath: rootURL.path) else {
            return []
        }

        let candidates = discoverCandidates(in: rootURL, patterns: patterns)
        var results: [SemanticCleanupUnit] = []

        for (url, reason) in candidates {
            let stats = await sizeCalculator.stats(of: url)
            guard stats.bytes > 20_000_000 else { continue }

            results.append(
                SemanticCleanupUnit(
                    id: url.path,
                    title: url.lastPathComponent,
                    path: url.path,
                    totalBytes: stats.bytes,
                    fileCount: stats.fileCount,
                    risk: .review,
                    reason: reason
                )
            )
        }

        return results.sorted(by: { $0.totalBytes > $1.totalBytes })
    }

    private func discoverCandidates(in rootURL: URL, patterns: [String: String]) -> [(URL, String)] {
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        let rootDepth = rootURL.pathComponents.count
        var matches: [(URL, String)] = []

        for case let url as URL in enumerator {
            let depth = url.pathComponents.count - rootDepth
            if depth > 6 {
                enumerator.skipDescendants()
                continue
            }

            let name = url.lastPathComponent.lowercased()
            if let reason = patterns.first(where: { name == $0.key || name.contains($0.key) })?.value {
                matches.append((url, reason))
                enumerator.skipDescendants()
            }
        }

        return matches
    }
}
