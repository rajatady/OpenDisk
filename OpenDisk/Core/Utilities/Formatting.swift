import Foundation

enum Formatting {
    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    static func bytes(_ value: Int64) -> String {
        byteFormatter.string(fromByteCount: value)
    }

    static func relativeDate(_ date: Date?) -> String {
        guard let date else {
            return "Unknown"
        }

        return date.formatted(.relative(presentation: .named))
    }
}
