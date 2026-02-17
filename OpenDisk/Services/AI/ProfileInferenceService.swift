import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct ProfileInferenceService: ProfileInferenceServiceProtocol {
    private let useFoundationModel: Bool
    private let processInfo: ProcessInfo

    init(useFoundationModel: Bool = true, processInfo: ProcessInfo = .processInfo) {
        self.useFoundationModel = useFoundationModel
        self.processInfo = processInfo
    }

    func inferProfile(apps: [InstalledApp], metadata: [FileMetadata]) async -> UserProfile {
        #if canImport(FoundationModels)
        if useFoundationModel,
           processInfo.environment["OPENDISK_DISABLE_FOUNDATION_MODEL"] != "1",
           #available(macOS 26.0, *),
           let modelProfile = await inferWithFoundationModel(apps: apps, metadata: metadata) {
            return modelProfile
        }
        #endif

        return inferHeuristically(apps: apps, metadata: metadata)
    }

    private func inferHeuristically(apps: [InstalledApp], metadata: [FileMetadata]) -> UserProfile {
        let corpus = apps.map { "\($0.displayName.lowercased()) \($0.bundleID.lowercased())" }.joined(separator: " ")
        var scores: [UserProfileKind: Double] = [:]
        var evidence: [ProfileEvidence] = []

        func add(_ kind: UserProfileKind, _ reason: String, _ weight: Double) {
            scores[kind, default: 0] += weight
            evidence.append(ProfileEvidence(reason: reason, weight: weight))
        }

        if corpus.contains("xcode") || corpus.contains("com.apple.dt.xcode") {
            add(.iosDeveloper, "Xcode installed", 0.9)
        }
        if corpus.contains("webstorm") || corpus.contains("vscode") || corpus.contains("node") {
            add(.webDeveloper, "Web development tooling detected", 0.8)
        }
        if corpus.contains("python") || corpus.contains("jupyter") || corpus.contains("tensorflow") || corpus.contains("pytorch") {
            add(.mlEngineer, "ML tooling detected", 1.0)
            add(.dataScientist, "Data science tooling detected", 0.7)
        }
        if corpus.contains("figma") || corpus.contains("adobe") || corpus.contains("sketch") {
            add(.designer, "Design applications detected", 0.9)
        }
        if corpus.contains("final cut") || corpus.contains("davinci") || corpus.contains("premiere") {
            add(.videoCreator, "Video editing software detected", 0.9)
        }

        let metadataSignal = metadata.reduce(0.0) { partial, item in
            let ext = item.extensionName.lowercased()
            if ["pt", "ckpt", "safetensors", "h5"].contains(ext) {
                return partial + 0.15
            }
            if ["psd", "sketch", "fig"].contains(ext) {
                return partial + 0.12
            }
            if ["mov", "mp4", "mxf", "r3d"].contains(ext) {
                return partial + 0.10
            }
            return partial
        }

        if metadataSignal > 0.3 {
            add(.mlEngineer, "Checkpoint-like artifacts detected", min(metadataSignal, 1.0))
        }

        let checkpointBytes = metadata
            .filter { entry in
                let path = entry.path.lowercased()
                let ext = entry.extensionName.lowercased()
                return path.contains("checkpoint")
                    || path.contains("tensorboard")
                    || path.contains("wandb")
                    || path.contains("/runs")
                    || ["pt", "ckpt", "safetensors"].contains(ext)
            }
            .reduce(Int64(0)) { $0 + $1.sizeBytes }
        if checkpointBytes > 2_000_000_000 {
            let weight = min(Double(checkpointBytes) / 20_000_000_000, 1.0)
            add(.mlEngineer, "Distributed checkpoint directories detected (\(Formatting.bytes(checkpointBytes)))", max(weight, 0.35))
        }

        let webBuildBytes = metadata
            .filter { entry in
                let path = entry.path.lowercased()
                return path.contains("node_modules") || path.contains(".next") || path.contains("dist")
            }
            .reduce(Int64(0)) { $0 + $1.sizeBytes }
        if webBuildBytes > 1_000_000_000 {
            let weight = min(Double(webBuildBytes) / 15_000_000_000, 1.0)
            add(.webDeveloper, "Web build/cache directories detected (\(Formatting.bytes(webBuildBytes)))", max(weight, 0.30))
        }

        let designAssetBytes = metadata
            .filter { ["psd", "fig", "sketch", "ai", "xd"].contains($0.extensionName.lowercased()) }
            .reduce(Int64(0)) { $0 + $1.sizeBytes }
        if designAssetBytes > 750_000_000 {
            add(.designer, "Large design-source assets detected (\(Formatting.bytes(designAssetBytes)))", min(Double(designAssetBytes) / 10_000_000_000, 0.8))
        }

        if scores.isEmpty {
            return UserProfile(kinds: [.generalUser], confidence: 0.5, evidence: [ProfileEvidence(reason: "No strong profile indicators found", weight: 0.5)])
        }

        let ordered = scores.sorted(by: { $0.value > $1.value })
        let total = ordered.reduce(0.0) { $0 + $1.value }
        let top = ordered.prefix(2).map(\.key)
        let confidence = min(max((ordered.first?.value ?? 0) / max(total, 0.1), 0.55), 0.99)

        return UserProfile(kinds: Array(top), confidence: confidence, evidence: evidence.sorted(by: { $0.weight > $1.weight }))
    }

    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private func inferWithFoundationModel(apps: [InstalledApp], metadata: [FileMetadata]) async -> UserProfile? {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            return nil
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You are classifying a macOS user's likely profile for disk cleanup personalization.
            Return strict JSON with this exact schema:
            {
              "kinds": ["iosDeveloper" | "webDeveloper" | "mlEngineer" | "designer" | "videoCreator" | "dataScientist" | "generalUser"],
              "confidence": 0.0 to 1.0,
              "evidence": [{"reason": "short reason", "weight": 0.0 to 1.0}]
            }
            Rules:
            - Include 1 to 2 kinds.
            - Prefer generalUser only when no strong signal exists.
            - Keep evidence concise and tied to provided app or file-pattern signals.
            - Return JSON only. No markdown, no prose.
            """
        )

        let prompt = buildPrompt(apps: apps, metadata: metadata)

        do {
            let response = try await session.respond(to: prompt)
            return parseFoundationModelResponse(response.content)
        } catch {
            return nil
        }
    }

    private func buildPrompt(apps: [InstalledApp], metadata: [FileMetadata]) -> String {
        let topApps = apps
            .sorted(by: { $0.trueSizeBytes > $1.trueSizeBytes })
            .prefix(60)
            .map { "\($0.displayName) [\($0.bundleID)]" }
            .joined(separator: ", ")

        let topExtensions = Dictionary(grouping: metadata, by: { $0.extensionName.lowercased() })
            .map { key, entries -> (String, Int64, Int) in
                let bytes = entries.reduce(Int64(0)) { $0 + $1.sizeBytes }
                let files = entries.reduce(0) { $0 + $1.fileCount }
                return (key, bytes, files)
            }
            .sorted(by: { $0.1 > $1.1 })
            .prefix(20)
            .map { "\($0.0):\($0.2) files,\(Formatting.bytes($0.1))" }
            .joined(separator: ", ")

        let largePathClusters = metadata
            .sorted(by: { $0.sizeBytes > $1.sizeBytes })
            .prefix(15)
            .map { "\($0.path) [\($0.extensionName)] -> \($0.fileCount) files, \(Formatting.bytes($0.sizeBytes))" }
            .joined(separator: ", ")

        return """
        App signals:
        \(topApps.isEmpty ? "none" : topApps)

        File pattern signals:
        \(topExtensions.isEmpty ? "none" : topExtensions)

        Large path clusters:
        \(largePathClusters.isEmpty ? "none" : largePathClusters)
        """
    }

    private func parseFoundationModelResponse(_ content: String) -> UserProfile? {
        let sanitized = sanitizeJSON(content)
        guard let data = sanitized.data(using: .utf8) else {
            return nil
        }

        do {
            let decoded = try JSONDecoder().decode(FoundationModelProfileResponse.self, from: data)
            let kinds = decoded.kinds.compactMap(UserProfileKind.init(rawValue:))
            guard !kinds.isEmpty else {
                return nil
            }

            let confidence = min(max(decoded.confidence, 0), 1)
            let evidence = decoded.evidence.map {
                ProfileEvidence(reason: $0.reason, weight: min(max($0.weight, 0), 1))
            }

            return UserProfile(kinds: Array(kinds.prefix(2)), confidence: max(confidence, 0.5), evidence: evidence)
        } catch {
            return nil
        }
    }

    private func sanitizeJSON(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```") {
            return trimmed
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }

    private struct FoundationModelProfileResponse: Decodable {
        struct Evidence: Decodable {
            let reason: String
            let weight: Double
        }

        let kinds: [String]
        let confidence: Double
        let evidence: [Evidence]
    }
    #endif
}
