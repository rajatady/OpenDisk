import XCTest
@testable import OpenDisk

final class PermissionServiceTests: XCTestCase {
    func testEnvironmentOverrideAuthorized() async {
        let service = PermissionService(environmentOverride: ["OPENDISK_PERMISSION_STATUS": "authorized"])

        let status = await service.permissionStatus()

        XCTAssertEqual(status, .authorized)
    }

    func testEnvironmentOverrideDenied() async {
        let service = PermissionService(environmentOverride: ["OPENDISK_PERMISSION_STATUS": "denied"])

        let status = await service.permissionStatus()

        XCTAssertEqual(status, .denied)
    }

    func testReturnsAuthorizedWhenProtectedProbeIsReadable() async throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let safari = home.appendingPathComponent("Library/Safari", isDirectory: true)
        try FileManager.default.createDirectory(at: safari, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: safari.appendingPathComponent("History.db").path, contents: Data())

        let service = PermissionService(homeDirectory: home)
        let status = await service.permissionStatus()
        XCTAssertEqual(status, .authorized)

        try? FileManager.default.removeItem(at: home)
    }

    func testReturnsNotDeterminedWhenNoProbePathExists() async throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)

        let service = PermissionService(homeDirectory: home)
        let status = await service.permissionStatus()
        XCTAssertEqual(status, .notDetermined)

        try? FileManager.default.removeItem(at: home)
    }
}
