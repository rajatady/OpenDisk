import XCTest
@testable import OpenDisk

final class OnboardingStateStoreTests: XCTestCase {
    func testStorePersistsSelectedValues() {
        let suiteName = "OpenDiskTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsOnboardingStateStore(defaults: defaults)
        XCTAssertFalse(store.isCompleted)

        store.isCompleted = true
        store.selectedScope = .fullDisk
        let now = Date()
        store.lastCompletedAt = now

        XCTAssertTrue(store.isCompleted)
        XCTAssertEqual(store.selectedScope, .fullDisk)
        XCTAssertNotNil(store.lastCompletedAt)
    }
}
