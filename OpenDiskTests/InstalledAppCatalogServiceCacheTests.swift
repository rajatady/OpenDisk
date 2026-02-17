import XCTest
@testable import OpenDisk

final class InstalledAppCatalogServiceCacheTests: XCTestCase {
    func testCatalogUsesCacheOnSubsequentFetch() async throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("OpenDiskTests-Apps-\(UUID().uuidString)", isDirectory: true)
        let appURL = root.appendingPathComponent("TestApp.app", isDirectory: true)
        let binaryURL = appURL.appendingPathComponent("Contents/MacOS/TestApp", isDirectory: false)
        let cacheURL = root.appendingPathComponent("app-cache.json", isDirectory: false)

        try fileManager.createDirectory(at: binaryURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("abc".utf8).write(to: binaryURL)

        let cacheStore = AppCatalogCacheStore(fileManager: fileManager, storageURL: cacheURL, cacheTTL: 3600)
        let service = InstalledAppCatalogService(
            fileManager: fileManager,
            sizeCalculator: FileSystemSizeCalculator(fileManager: fileManager),
            scanRoots: [root],
            cacheStore: cacheStore,
            cacheTTL: 3600
        )

        let first = try await service.fetchInstalledApps(onProgress: nil)
        let firstInfo = await service.latestFetchInfo()

        let second = try await service.fetchInstalledApps(onProgress: nil)
        let secondInfo = await service.latestFetchInfo()

        XCTAssertEqual(first.count, 1)
        XCTAssertEqual(second.count, first.count)
        XCTAssertEqual(firstInfo.source, .live)
        XCTAssertEqual(secondInfo.source, .cached)

        try? fileManager.removeItem(at: root)
    }
}
