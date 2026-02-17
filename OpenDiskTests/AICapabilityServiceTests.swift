import XCTest
@testable import OpenDisk

final class AICapabilityServiceTests: XCTestCase {
    func testEnvironmentOverrideForcesSupported() {
        let service = AICapabilityService(environmentOverride: ["OPENDISK_AI_SUPPORTED": "1"])

        let status = service.capabilityStatus()

        XCTAssertTrue(status.isSupported)
    }

    func testEnvironmentOverrideForcesUnsupported() {
        let service = AICapabilityService(environmentOverride: ["OPENDISK_AI_SUPPORTED": "0"])

        let status = service.capabilityStatus()

        guard case .unsupported(let reason) = status else {
            XCTFail("Expected unsupported status")
            return
        }

        XCTAssertTrue(reason.contains("required"))
    }
}
