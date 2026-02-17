import Foundation

actor InstalledAppCatalogService: InstalledAppCatalogServiceProtocol, AppCatalogFetchInfoProvider {
    nonisolated(unsafe) private let fileManager: FileManager
    private let sizeCalculator: FileSystemSizeCalculator
    private let scanRoots: [URL]
    private let cacheStore: AppCatalogCacheStore
    private var lastInfo = AppCatalogFetchInfo(source: .live, fetchedAt: .distantPast)

    init(
        fileManager: FileManager = .default,
        sizeCalculator: FileSystemSizeCalculator,
        scanRoots: [URL]? = nil,
        cacheStore: AppCatalogCacheStore? = nil,
        cacheTTL: TimeInterval = 60 * 15
    ) {
        self.fileManager = fileManager
        self.sizeCalculator = sizeCalculator
        self.scanRoots = scanRoots ?? [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications"),
            URL(fileURLWithPath: "/opt/homebrew/Caskroom")
        ]

        if let cacheStore {
            self.cacheStore = cacheStore
        } else {
            self.cacheStore = AppCatalogCacheStore(fileManager: fileManager, cacheTTL: cacheTTL)
        }
    }

    func latestFetchInfo() async -> AppCatalogFetchInfo {
        lastInfo
    }

    func fetchInstalledApps(onProgress: ((AppScanProgress) -> Void)? = nil) async throws -> [InstalledApp] {
        onProgress?(AppScanProgress(message: "Preparing app catalog scan...", completed: 0, total: 1))

        if let cached = await cacheStore.loadFresh() {
            let info = AppCatalogFetchInfo(source: .cached, fetchedAt: cached.generatedAt)
            lastInfo = info

            onProgress?(AppScanProgress(message: "Loaded cached app catalog.", completed: 1, total: 1))
            return cached.apps
        }

        onProgress?(AppScanProgress(message: "Discovering installed apps...", completed: 0, total: 1))

        var appURLs = Set<URL>()
        for root in scanRoots where fileManager.fileExists(atPath: root.path) {
            appURLs.formUnion(scanForBundles(in: root, maxDepth: root.path.contains("Caskroom") ? 4 : 2))
        }

        let sortedURLs = appURLs.sorted(by: { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() })
        let total = sortedURLs.count
        var apps: [InstalledApp] = []

        if total == 0 {
            onProgress?(AppScanProgress(message: "No installed apps found in scanned locations.", completed: 1, total: 1))
        }

        for (index, url) in sortedURLs.enumerated() {
            onProgress?(AppScanProgress(message: "Measuring \(url.deletingPathExtension().lastPathComponent)...", completed: index, total: total))

            let bundle = Bundle(url: url)
            let bundleID = bundle?.bundleIdentifier ?? "unknown.\(url.deletingPathExtension().lastPathComponent.lowercased())"
            let displayName = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? url.deletingPathExtension().lastPathComponent
            let executablePath = bundle?.executableURL?.path
            let values = try? url.resourceValues(forKeys: [.contentAccessDateKey])
            let lastUsed = values?.contentAccessDate
            let bundleSize = await sizeCalculator.size(of: url)

            apps.append(
                InstalledApp(
                    id: "\(bundleID):\(url.path)",
                    displayName: displayName,
                    bundleID: bundleID,
                    bundlePath: url.path,
                    executablePath: executablePath,
                    lastUsedDate: lastUsed,
                    bundleSizeBytes: bundleSize
                )
            )

            onProgress?(AppScanProgress(message: "Processed \(index + 1) of \(total) apps", completed: index + 1, total: total))
        }

        let generatedAt = Date()
        await cacheStore.save(apps: apps, generatedAt: generatedAt)
        lastInfo = AppCatalogFetchInfo(source: .live, fetchedAt: generatedAt)

        onProgress?(AppScanProgress(message: "App discovery complete.", completed: max(total, 1), total: max(total, 1)))

        return apps
    }

    private func scanForBundles(in root: URL, maxDepth: Int) -> Set<URL> {
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .nameKey]
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let rootDepth = root.pathComponents.count
        var results = Set<URL>()

        for case let url as URL in enumerator {
            let depth = url.pathComponents.count - rootDepth
            if depth > maxDepth {
                enumerator.skipDescendants()
                continue
            }

            if url.pathExtension.lowercased() == "app" {
                results.insert(url)
                enumerator.skipDescendants()
            }
        }

        return results
    }
}

actor AppCatalogCacheStore {
    struct Entry: Hashable, Codable, Sendable {
        let generatedAt: Date
        let apps: [InstalledApp]
    }

    nonisolated(unsafe) private let fileManager: FileManager
    private let storageURL: URL
    private let cacheTTL: TimeInterval

    init(fileManager: FileManager = .default, storageURL: URL? = nil, cacheTTL: TimeInterval) {
        self.fileManager = fileManager
        self.cacheTTL = cacheTTL

        if let storageURL {
            self.storageURL = storageURL
        } else {
            let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.storageURL = base
                .appendingPathComponent("OpenDisk", isDirectory: true)
                .appendingPathComponent("app-catalog-cache.json")
        }
    }

    func loadFresh(now: Date = Date()) -> Entry? {
        guard let entry = loadRaw() else {
            return nil
        }

        guard now.timeIntervalSince(entry.generatedAt) <= cacheTTL else {
            return nil
        }

        return entry
    }

    func save(apps: [InstalledApp], generatedAt: Date = Date()) {
        let entry = Entry(generatedAt: generatedAt, apps: apps)
        saveRaw(entry)
    }

    private func loadRaw() -> Entry? {
        guard let data = try? Data(contentsOf: storageURL) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Entry.self, from: data)
    }

    private func saveRaw(_ entry: Entry) {
        do {
            let directory = storageURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(entry)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            return
        }
    }
}
