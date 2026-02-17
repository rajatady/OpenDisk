import Foundation
import Combine

@MainActor
final class StorageMapViewModel: ObservableObject {
    @Published private(set) var state = StorageMapViewState(
        root: nil,
        isLoading: false,
        scanMessage: "",
        scanProgress: nil,
        usedCachedResults: false,
        lastScanAt: nil,
        errorMessage: nil
    )

    private let diskScanner: DiskScannerProtocol
    private let cacheStore: StorageMapCacheStoreProtocol

    init(container: AppContainer) {
        self.diskScanner = container.diskScanner
        self.cacheStore = container.storageMapCacheStore
    }

    func load(scope: ScanScope, forceRefresh: Bool = false) async {
        state.isLoading = true
        state.errorMessage = nil
        state.scanMessage = "Preparing storage map..."
        state.scanProgress = 0
        state.usedCachedResults = false

        let rootURL = scope.rootURL
        let cacheKey = "\(scope.rawValue)|\(rootURL.path)"

        if !forceRefresh, let cached = await cacheStore.load(key: cacheKey, maxAge: 60 * 20) {
            state.root = cached.root
            state.isLoading = false
            state.scanMessage = "Loaded cached map."
            state.scanProgress = 1
            state.usedCachedResults = true
            state.lastScanAt = cached.createdAt
            return
        }

        do {
            state.scanMessage = "Scanning \(rootURL.path)..."
            state.scanProgress = 0.25

            let root = try await diskScanner.scan(root: rootURL)
            let generatedAt = Date()

            state.scanMessage = "Building visual map..."
            state.scanProgress = 0.8

            await cacheStore.save(entry: StorageMapCacheEntry(key: cacheKey, createdAt: generatedAt, root: root))

            state.root = root
            state.scanMessage = "Storage map ready."
            state.scanProgress = 1
            state.lastScanAt = generatedAt
            state.usedCachedResults = false
            state.isLoading = false
        } catch {
            state.errorMessage = error.localizedDescription
            state.scanMessage = "Failed to scan storage."
            state.scanProgress = nil
            state.isLoading = false
        }
    }
}

private extension ScanScope {
    var rootURL: URL {
        switch self {
        case .home:
            return URL(fileURLWithPath: NSHomeDirectory())
        case .applications:
            return URL(fileURLWithPath: "/Applications")
        case .fullDisk:
            return URL(fileURLWithPath: "/")
        }
    }
}
