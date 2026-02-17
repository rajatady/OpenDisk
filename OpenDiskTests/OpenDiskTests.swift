import XCTest
@testable import OpenDisk

final class OpenDiskTests: XCTestCase {
    func testFormattingBytesProducesReadableUnits() {
        let text = Formatting.bytes(1_500_000_000)
        XCTAssertFalse(text.isEmpty)
        XCTAssertTrue(text.contains("GB") || text.contains("MB"))
    }
}
