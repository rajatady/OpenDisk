import Foundation

actor FileSystemSizeCalculator {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func size(of url: URL) -> Int64 {
        stats(of: url).bytes
    }

    func stats(of url: URL) -> (bytes: Int64, fileCount: Int) {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey, .isDirectoryKey]

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return (0, 0)
        }

        var total: Int64 = 0
        var count = 0

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: keys) else { continue }
            if values.isRegularFile == true {
                total += Int64(values.fileSize ?? 0)
                count += 1
            }
        }

        if total == 0,
           let attrs = try? fileManager.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? NSNumber {
            return (size.int64Value, max(count, 1))
        }

        return (total, count)
    }
}
