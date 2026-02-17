import Foundation

final class AppArtifactResolverService: AppArtifactResolverProtocol {
    private let fileManager: FileManager
    private let sizeCalculator: FileSystemSizeCalculator
    private let userHome: URL

    init(
        fileManager: FileManager = .default,
        sizeCalculator: FileSystemSizeCalculator,
        userHome: URL = URL(fileURLWithPath: NSHomeDirectory())
    ) {
        self.fileManager = fileManager
        self.sizeCalculator = sizeCalculator
        self.userHome = userHome
    }

    func artifacts(for app: InstalledApp) async -> [AssociatedArtifact] {
        var urls = Set<URL>()
        let appName = URL(fileURLWithPath: app.bundlePath).deletingPathExtension().lastPathComponent
        let bundleID = app.bundleID

        let userLibrary = userHome.appendingPathComponent("Library")

        urls.insert(URL(fileURLWithPath: app.bundlePath))
        urls.formUnion([
            userLibrary.appendingPathComponent("Application Support/\(bundleID)"),
            userLibrary.appendingPathComponent("Application Support/\(appName)"),
            userLibrary.appendingPathComponent("Caches/\(bundleID)"),
            userLibrary.appendingPathComponent("Caches/\(appName)"),
            userLibrary.appendingPathComponent("Preferences/\(bundleID).plist"),
            userLibrary.appendingPathComponent("Saved Application State/\(bundleID).savedState"),
            userLibrary.appendingPathComponent("Containers/\(bundleID)"),
            userLibrary.appendingPathComponent("HTTPStorages/\(bundleID)"),
            userLibrary.appendingPathComponent("WebKit/\(bundleID)"),
            userLibrary.appendingPathComponent("Logs/\(bundleID)"),
            userLibrary.appendingPathComponent("Logs/\(appName)"),
            URL(fileURLWithPath: "/Library/Application Support/\(appName)"),
            URL(fileURLWithPath: "/Library/PreferencePanes/\(appName).prefPane")
        ])

        urls.formUnion(matchingEntries(in: userLibrary.appendingPathComponent("Group Containers"), tokens: [bundleID]))
        urls.formUnion(matchingEntries(in: userLibrary.appendingPathComponent("LaunchAgents"), tokens: [bundleID]))
        urls.formUnion(matchingEntries(in: URL(fileURLWithPath: "/Library/LaunchAgents"), tokens: [bundleID]))
        urls.formUnion(matchingEntries(in: URL(fileURLWithPath: "/Library/LaunchDaemons"), tokens: [bundleID]))

        var artifacts: [AssociatedArtifact] = []

        for url in urls where fileManager.fileExists(atPath: url.path) {
            let size = await sizeCalculator.size(of: url)
            if size == 0 { continue }

            let kind = classify(url: url, bundlePath: app.bundlePath)
            let isDirectory: Bool = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            artifacts.append(
                AssociatedArtifact(
                    path: url.path,
                    groupKind: kind,
                    safetyLevel: safety(for: kind),
                    sizeBytes: size,
                    isDirectory: isDirectory
                )
            )
        }

        return artifacts.sorted(by: { $0.sizeBytes > $1.sizeBytes })
    }

    func orphanArtifacts(existingBundleIDs: Set<String>) async -> [AssociatedArtifact] {
        let scanRoots = [
            userHome.appendingPathComponent("Library/Containers"),
            userHome.appendingPathComponent("Library/Caches"),
            userHome.appendingPathComponent("Library/Application Support"),
            userHome.appendingPathComponent("Library/Preferences")
        ]

        var artifacts: [AssociatedArtifact] = []

        for root in scanRoots where fileManager.fileExists(atPath: root.path) {
            guard let contents = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
                continue
            }

            for entry in contents {
                let name = entry.lastPathComponent
                guard let bundleID = extractBundleID(from: name), !existingBundleIDs.contains(bundleID) else {
                    continue
                }

                let size = await sizeCalculator.size(of: entry)
                guard size > 0 else { continue }

                let kind = classify(url: entry, bundlePath: "")
                let isDirectory: Bool = (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                artifacts.append(
                    AssociatedArtifact(
                        path: entry.path,
                        groupKind: kind,
                        safetyLevel: safety(for: kind),
                        sizeBytes: size,
                        isDirectory: isDirectory
                    )
                )
            }
        }

        return artifacts.sorted(by: { $0.sizeBytes > $1.sizeBytes })
    }

    private func classify(url: URL, bundlePath: String) -> ArtifactGroupKind {
        let path = url.path
        if path == bundlePath {
            return .appBundle
        }
        if path.contains("/Caches/") || path.contains("/Logs/") {
            return .cache
        }
        if path.contains("/Preferences/") {
            return .preferences
        }
        if path.contains("/LaunchAgents/") || path.contains("/LaunchDaemons/") || path.contains("/PreferencePanes/") {
            return .systemIntegration
        }
        return .userData
    }

    private func safety(for kind: ArtifactGroupKind) -> SafetyLevel {
        switch kind {
        case .cache:
            return .safe
        case .preferences, .appBundle, .userData:
            return .review
        case .systemIntegration:
            return .risky
        }
    }

    private func matchingEntries(in root: URL, tokens: [String]) -> Set<URL> {
        guard fileManager.fileExists(atPath: root.path),
              let contents = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
            return []
        }

        let loweredTokens = tokens.map { $0.lowercased() }
        return Set(contents.filter { entry in
            let lowered = entry.lastPathComponent.lowercased()
            return loweredTokens.contains(where: lowered.contains)
        })
    }

    private func extractBundleID(from name: String) -> String? {
        let source = name.replacingOccurrences(of: ".plist", with: "")
        guard source.contains("."), source.count > 6 else { return nil }
        return source
    }
}
