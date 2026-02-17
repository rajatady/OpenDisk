import Foundation

actor RecommendationsCacheStore: RecommendationsCacheStoreProtocol {
    private let fileManager: FileManager
    private let storageURL: URL
    private var entries: [String: RecommendationsCacheEntry] = [:]

    nonisolated init(fileManager: FileManager = .default, storageURL: URL? = nil) {
        self.fileManager = fileManager

        if let storageURL {
            self.storageURL = storageURL
        } else {
            let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.storageURL = base
                .appendingPathComponent("OpenDisk", isDirectory: true)
                .appendingPathComponent("recommendations-cache.json")
        }

        self.entries = Self.load(fileManager: fileManager, url: self.storageURL)
    }

    func load(key: String, maxAge: TimeInterval) async -> RecommendationsCacheEntry? {
        guard let entry = entries[key] else {
            return nil
        }

        if Date().timeIntervalSince(entry.createdAt) > maxAge {
            entries.removeValue(forKey: key)
            persist()
            return nil
        }

        return entry
    }

    func save(entry: RecommendationsCacheEntry) async {
        entries[entry.key] = entry
        persist()
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
            let data = try encoder.encode(entries)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            return
        }
    }

    private static func load(fileManager: FileManager, url: URL) -> [String: RecommendationsCacheEntry] {
        guard fileManager.fileExists(atPath: url.path), let data = try? Data(contentsOf: url) else {
            return [:]
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([String: RecommendationsCacheEntry].self, from: data)) ?? [:]
    }
}
