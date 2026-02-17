import Foundation

struct MetadataDiscoveryService: MetadataDiscoveryServiceProtocol {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func collectMetadata(in rootURL: URL, maxDepth: Int = 5, maxSamples: Int = 2_500) async -> [FileMetadata] {
        collectMetadataSync(in: rootURL, maxDepth: maxDepth, maxSamples: maxSamples)
    }

    private func collectMetadataSync(in rootURL: URL, maxDepth: Int, maxSamples: Int) -> [FileMetadata] {
        guard fileManager.fileExists(atPath: rootURL.path) else {
            return []
        }

        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        struct Aggregate {
            var bytes: Int64 = 0
            var count: Int = 0
            var depth: Int = 0
        }

        let rootDepth = rootURL.pathComponents.count
        var buckets: [String: Aggregate] = [:]
        var sampledFiles = 0

        for case let url as URL in enumerator {
            if sampledFiles >= maxSamples {
                break
            }

            let depth = url.pathComponents.count - rootDepth
            if depth > maxDepth {
                enumerator.skipDescendants()
                continue
            }

            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .isRegularFileKey]) else {
                continue
            }

            if values.isDirectory == true {
                continue
            }

            guard values.isRegularFile == true, let fileSize = values.fileSize else {
                continue
            }

            sampledFiles += 1
            let ext = url.pathExtension.lowercased()
            let normalizedExt = ext.isEmpty ? "none" : ext
            let parent = url.deletingLastPathComponent().path
            let key = "\(parent)|\(normalizedExt)"

            var aggregate = buckets[key] ?? Aggregate()
            aggregate.bytes += Int64(fileSize)
            aggregate.count += 1
            aggregate.depth = depth
            buckets[key] = aggregate
        }

        return buckets
            .map { key, aggregate in
                let components = key.split(separator: "|", maxSplits: 1).map(String.init)
                return FileMetadata(
                    path: components.first ?? rootURL.path,
                    sizeBytes: aggregate.bytes,
                    fileCount: aggregate.count,
                    depth: aggregate.depth,
                    extensionName: components.count > 1 ? components[1] : "none"
                )
            }
            .sorted(by: { $0.sizeBytes > $1.sizeBytes })
            .prefix(300)
            .map { $0 }
    }
}
