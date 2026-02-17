import Foundation

struct RecommendationRankerService: RecommendationRankerProtocol {
    func rank(profile: UserProfile, apps: [InstalledApp], semanticUnits: [SemanticCleanupUnit]) -> [Recommendation] {
        let topApps = apps.sorted(by: { $0.trueSizeBytes > $1.trueSizeBytes }).prefix(8)
        let appRecommendations = topApps.map { app in
            Recommendation(
                id: "app:\(app.id)",
                title: "Review \(app.displayName)",
                detail: "Potential reclaim: \(Formatting.bytes(app.trueSizeBytes)). Includes app support artifacts.",
                path: app.bundlePath,
                impactScore: score(bytes: app.trueSizeBytes),
                confidenceScore: min(profile.confidence + 0.1, 0.99),
                riskScore: 0.4,
                reversible: true
            )
        }

        let unitRecommendations = semanticUnits.prefix(8).map { unit in
            Recommendation(
                id: "unit:\(unit.id)",
                title: "Cleanup unit: \(unit.title)",
                detail: "\(unit.reason) Estimated reclaim: \(Formatting.bytes(unit.totalBytes)) across \(unit.fileCount) files.",
                path: unit.path,
                impactScore: score(bytes: unit.totalBytes),
                confidenceScore: min(profile.confidence + 0.15, 0.99),
                riskScore: riskScore(for: unit.risk),
                reversible: true
            )
        }

        return (appRecommendations + unitRecommendations)
            .sorted { lhs, rhs in
                let lhsScore = compositeScore(for: lhs, profile: profile)
                let rhsScore = compositeScore(for: rhs, profile: profile)
                return lhsScore > rhsScore
            }
    }

    private func score(bytes: Int64) -> Double {
        let gb = Double(bytes) / 1_073_741_824
        return min(max(gb / 10.0, 0.05), 1.0)
    }

    private func compositeScore(for recommendation: Recommendation, profile: UserProfile) -> Double {
        let affinity = profileAffinity(profile: profile, recommendation: recommendation)
        let riskPenalty = recommendation.riskScore * 0.15
        return (recommendation.impactScore * 0.50)
            + (recommendation.confidenceScore * 0.25)
            + (affinity * 0.25)
            - riskPenalty
    }

    private func profileAffinity(profile: UserProfile, recommendation: Recommendation) -> Double {
        let context = "\(recommendation.title.lowercased()) \(recommendation.path?.lowercased() ?? "") \(recommendation.detail.lowercased())"
        var score = 0.2

        for kind in profile.kinds {
            switch kind {
            case .iosDeveloper:
                if context.contains("xcode") || context.contains("deriveddata") || context.contains("simulator") {
                    score += 0.45
                }
            case .webDeveloper:
                if context.contains("node_modules") || context.contains(".next") || context.contains("dist") || context.contains("webpack") {
                    score += 0.45
                }
            case .mlEngineer:
                if context.contains("checkpoint") || context.contains("tensorboard") || context.contains("wandb") || context.contains("model") {
                    score += 0.48
                }
            case .designer:
                if context.contains("figma") || context.contains("adobe") || context.contains("sketch") || context.contains("assets") {
                    score += 0.42
                }
            case .videoCreator:
                if context.contains("final cut") || context.contains("davinci") || context.contains("premiere") || context.contains("render") {
                    score += 0.42
                }
            case .dataScientist:
                if context.contains("jupyter") || context.contains("notebook") || context.contains("dataset") || context.contains("cache") {
                    score += 0.40
                }
            case .generalUser:
                if context.contains("cache") || context.contains("orphan") {
                    score += 0.25
                }
            }
        }

        return min(score, 1.0)
    }

    private func riskScore(for level: SafetyLevel) -> Double {
        switch level {
        case .safe:
            return 0.2
        case .review:
            return 0.35
        case .risky:
            return 0.7
        }
    }
}
