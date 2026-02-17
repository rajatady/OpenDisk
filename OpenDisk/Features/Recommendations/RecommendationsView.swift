import SwiftUI

struct RecommendationsView: View {
    @ObservedObject var viewModel: RecommendationsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: ODSpacing.md) {
            header
            content
        }
        .padding(ODSpacing.lg)
        .odCanvasBackground()
    }

    // MARK: - Header

    private var header: some View {
        GlassPanel(style: .hero) {
            HStack(spacing: ODSpacing.lg) {
                VStack(alignment: .leading, spacing: ODSpacing.sm) {
                    Text("Smart Cleanup")
                        .odTextStyle(.display)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ODColors.textPrimary, ODColors.textPrimary.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    if let profile = viewModel.state.profile {
                        HStack(spacing: ODSpacing.sm) {
                            ForEach(profile.kinds, id: \.self) { kind in
                                Text(kind.rawValue)
                                    .odTextStyle(.caption)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, ODSpacing.sm)
                                    .padding(.vertical, 3)
                                    .background(profileKindTint(kind), in: Capsule())
                            }
                        }

                        HStack(spacing: ODSpacing.xs) {
                            Image(systemName: viewModel.state.usedCachedResults ? "cylinder.split.1x2.fill" : "sparkles")
                                .odIcon(.caption)
                            Text(viewModel.state.usedCachedResults ? "Cached recommendations" : "Live recommendations")
                        }
                        .odTextStyle(.caption, color: viewModel.state.usedCachedResults ? .safe : .textSecondary)
                    } else {
                        Text("Profile-aware recommendations are loading.")
                            .odTextStyle(.body, color: .textSecondary)
                    }
                }

                Spacer()

                if let profile = viewModel.state.profile {
                    VStack(spacing: ODSpacing.xs) {
                        ProgressRing(
                            progress: profile.confidence,
                            lineWidth: 4,
                            size: 48
                        )
                        Text("Confidence")
                            .odTextStyle(.caption, color: .textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading {
            VStack(spacing: ODSpacing.lg) {
                Spacer()
                ProgressRing(progress: nil, lineWidth: 5, size: 56)
                Text("Analyzing profile and semantic cleanup units...")
                    .odTextStyle(.body, color: .textSecondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else if let error = viewModel.state.errorMessage {
            EmptyState(
                icon: "exclamationmark.triangle",
                message: "Error",
                detail: error
            )
        } else if viewModel.state.recommendations.isEmpty {
            EmptyState(
                icon: "sparkles",
                message: "No Recommendations",
                detail: "Your disk is looking clean. Run a scan to check again."
            )
        } else {
            ScrollView {
                VStack(spacing: ODSpacing.sm) {
                    ForEach(Array(viewModel.state.recommendations.enumerated()), id: \.element.id) { index, recommendation in
                        AnimatedListRow(index: index) {
                            recommendationCard(recommendation, index: index)
                        }
                    }
                }
                .padding(.vertical, ODSpacing.xs)
            }
        }
    }

    // MARK: - Recommendation Card

    private func recommendationCard(_ recommendation: Recommendation, index: Int) -> some View {
        HoverCard {
            GlassPanel(style: .card) {
                HStack(spacing: ODSpacing.md) {
                    // Priority indicator
                    VStack {
                        Text("#\(index + 1)")
                            .odTextStyle(.caption)
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(priorityTint(for: recommendation.riskScore), in: Circle())
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: ODSpacing.sm) {
                        // Title + impact
                        HStack {
                            Text(recommendation.title)
                                .odTextStyle(.heading)
                            Spacer()
                            impactBar(score: recommendation.impactScore)
                        }

                        // Detail
                        Text(recommendation.detail)
                            .odTextStyle(.body, color: .textSecondary)
                            .lineLimit(2)

                        // Path
                        if let path = recommendation.path {
                            Text(path)
                                .odTextStyle(.mono)
                                .foregroundStyle(ODColors.textSecondary)
                                .lineLimit(1)
                                .padding(.horizontal, ODSpacing.sm)
                                .padding(.vertical, 3)
                                .background(ODColors.insetSurface, in: RoundedRectangle(cornerRadius: ODRadius.sm / 2, style: .continuous))
                        }

                        // Meta row
                        HStack(spacing: ODSpacing.md) {
                            HStack(spacing: ODSpacing.xs) {
                                Image(systemName: "gauge.with.needle")
                                    .odIcon(.caption)
                                Text("\(Int(recommendation.confidenceScore * 100))%")
                            }
                            .odTextStyle(.caption, color: .textSecondary)

                            SafetyLabel(level: safetyLevel(for: recommendation.riskScore))

                            HStack(spacing: ODSpacing.xs) {
                                Image(systemName: recommendation.reversible ? "arrow.uturn.backward.circle" : "exclamationmark.circle")
                                    .odIcon(.caption)
                                Text(recommendation.reversible ? "Reversible" : "Permanent")
                            }
                            .odTextStyle(.caption, color: recommendation.reversible ? .safe : .review)

                            Spacer()

                            SizeBadge(
                                bytes: Int64(recommendation.impactScore * 10_000_000_000),
                                level: safetyLevel(for: recommendation.riskScore)
                            )
                        }
                    }
                }
            }
        }
    }

    // Impact mini-bar
    private func impactBar(score: Double) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Double(i) / 5.0 < score ? ODColors.accent : ODColors.insetSurface)
                    .frame(width: 4, height: 14)
            }
        }
    }

    private func priorityTint(for riskScore: Double) -> Color {
        if riskScore < 0.3 { return ODColors.safe }
        if riskScore < 0.6 { return ODColors.review }
        return ODColors.risky
    }

    private func profileKindTint(_ kind: UserProfileKind) -> Color {
        switch kind {
        case .iosDeveloper: return .blue
        case .webDeveloper: return .cyan
        case .mlEngineer: return .orange
        case .designer: return .purple
        case .videoCreator: return .pink
        case .dataScientist: return .teal
        case .generalUser: return .gray
        }
    }

    private func safetyLevel(for riskScore: Double) -> SafetyLevel {
        if riskScore < 0.3 { return .safe }
        if riskScore < 0.6 { return .review }
        return .risky
    }
}
