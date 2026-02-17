import Foundation

struct DiskScannerService: DiskScannerProtocol {
    private let fileManager: FileManager
    private let sizeCalculator: FileSystemSizeCalculator

    init(fileManager: FileManager = .default, sizeCalculator: FileSystemSizeCalculator) {
        self.fileManager = fileManager
        self.sizeCalculator = sizeCalculator
    }

    func scan(root: URL) async throws -> DiskNode {
        try await scanNode(url: root, depth: 0, maxDepth: 3)
    }

    private func scanNode(url: URL, depth: Int, maxDepth: Int) async throws -> DiskNode {
        let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false

        if !isDirectory || depth >= maxDepth {
            let bytes = await sizeCalculator.size(of: url)
            return DiskNode(
                id: url.path,
                name: url.lastPathComponent,
                path: url.path,
                sizeBytes: bytes,
                isDirectory: isDirectory,
                children: []
            )
        }

        let childrenURLs = (try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        var children: [DiskNode] = []
        for child in childrenURLs.prefix(200) {
            let node = try await scanNode(url: child, depth: depth + 1, maxDepth: maxDepth)
            children.append(node)
        }

        let total = children.reduce(0) { $0 + $1.sizeBytes }
        return DiskNode(
            id: url.path,
            name: url.lastPathComponent,
            path: url.path,
            sizeBytes: total,
            isDirectory: true,
            children: children.sorted(by: { $0.sizeBytes > $1.sizeBytes })
        )
    }
}
