import AppKit
import Darwin
import Foundation

final class PermissionService: PermissionServiceProtocol {
    private let fileManager: FileManager
    private let environment: [String: String]
    private let homeDirectory: URL

    init(
        fileManager: FileManager = .default,
        processInfo: ProcessInfo = .processInfo,
        environmentOverride: [String: String]? = nil,
        homeDirectory: URL = URL(fileURLWithPath: NSHomeDirectory())
    ) {
        self.fileManager = fileManager
        self.environment = environmentOverride ?? processInfo.environment
        self.homeDirectory = homeDirectory
    }

    func permissionStatus() async -> PermissionStatus {
        if let forced = environment["OPENDISK_PERMISSION_STATUS"] {
            switch forced.lowercased() {
            case "authorized":
                return .authorized
            case "denied":
                return .denied
            default:
                return .notDetermined
            }
        }

        let protectedDirectoryProbes = [
            homeDirectory.appendingPathComponent("Library/Safari"),
            homeDirectory.appendingPathComponent("Library/Cookies"),
            homeDirectory.appendingPathComponent("Library/Mail"),
            homeDirectory.appendingPathComponent("Library/Messages"),
            homeDirectory.appendingPathComponent("Library/Calendars"),
            homeDirectory.appendingPathComponent("Library/Application Support/AddressBook")
        ]

        let existingProbes = protectedDirectoryProbes.filter { probe in
            fileManager.fileExists(atPath: probe.path)
        }

        guard !existingProbes.isEmpty else {
            return .notDetermined
        }

        var sawPermissionDenied = false

        for probe in existingProbes {
            do {
                _ = try fileManager.contentsOfDirectory(atPath: probe.path)
                return .authorized
            } catch let nsError as NSError {
                if isPermissionDenied(nsError) {
                    sawPermissionDenied = true
                }
            }
        }

        return sawPermissionDenied ? .denied : .notDetermined
    }

    func openSystemSettingsForFullDiskAccess() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func isPermissionDenied(_ error: NSError) -> Bool {
        if error.domain == NSCocoaErrorDomain, error.code == NSFileReadNoPermissionError {
            return true
        }

        if error.domain == NSPOSIXErrorDomain, error.code == Int(EACCES) || error.code == Int(EPERM) {
            return true
        }

        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            return isPermissionDenied(underlying)
        }

        return false
    }
}
