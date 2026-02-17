import XCTest

final class DesignSystemComplianceTests: XCTestCase {
    func testFeatureViewsUseDesignSystemTypographyAndAvoidHardcodedColors() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let featuresURL = root.appendingPathComponent("OpenDisk/Features")

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: featuresURL, includingPropertiesForKeys: nil) else {
            XCTFail("Could not enumerate feature files")
            return
        }

        var violations: [String] = []
        let forbiddenColorTokens = [
            ".blue", ".green", ".orange", ".purple", ".pink",
            ".red", ".yellow", ".teal", ".mint", ".indigo",
            ".brown", ".gray", ".black", ".white"
        ]

        for case let fileURL as URL in enumerator where fileURL.pathExtension == "swift" {
            let source = try String(contentsOf: fileURL)
            if source.contains(".font(") {
                violations.append("\(fileURL.path): direct .font usage")
            }
            if source.contains("Color(") {
                violations.append("\(fileURL.path): hardcoded Color usage")
            }
            for token in forbiddenColorTokens where source.contains("return \(token)") || source.contains("foregroundStyle(\(token)") || source.contains("fill(\(token)") {
                violations.append("\(fileURL.path): raw SwiftUI color token \(token)")
            }
        }

        XCTAssertTrue(violations.isEmpty, violations.joined(separator: "\n"))
    }
}
