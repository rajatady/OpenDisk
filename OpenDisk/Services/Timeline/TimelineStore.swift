import Foundation

actor TimelineStore: TimelineStoreProtocol {
    nonisolated(unsafe) private let fileManager: FileManager
    private let storageURL: URL
    private let maxItems: Int
    private var items: [DiskSnapshot]

    init(
        fileManager: FileManager = .default,
        storageURL: URL? = nil,
        maxItems: Int = 600
    ) {
        self.fileManager = fileManager
        self.maxItems = maxItems

        if let storageURL {
            self.storageURL = storageURL
        } else {
            let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.storageURL = base
                .appendingPathComponent("OpenDisk", isDirectory: true)
                .appendingPathComponent("timeline-snapshots.json")
        }

        self.items = Self.load(fileManager: fileManager, url: self.storageURL)
    }

    func save(snapshot: DiskSnapshot) async {
        items.append(snapshot)
        items.sort(by: { $0.capturedAt < $1.capturedAt })

        if items.count > maxItems {
            items.removeFirst(items.count - maxItems)
        }

        persist()
    }

    func snapshots() async -> [DiskSnapshot] {
        items
    }

    private func persist() {
        do {
            let directory = storageURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(items)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            return
        }
    }

    private static func load(fileManager: FileManager, url: URL) -> [DiskSnapshot] {
        guard fileManager.fileExists(atPath: url.path), let data = try? Data(contentsOf: url) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([DiskSnapshot].self, from: data)) ?? []
    }
}
