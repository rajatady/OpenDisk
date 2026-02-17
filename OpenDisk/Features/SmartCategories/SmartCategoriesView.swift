import SwiftUI

struct SmartCategoriesView: View {
    @ObservedObject var viewModel: SmartCategoriesViewModel

    var body: some View {
        VStack(spacing: ODSpacing.md) {
            header
            summaryCards
            categoriesPanel
        }
        .padding(ODSpacing.lg)
        .odCanvasBackground()
    }

    private var header: some View {
        GlassPanel(style: .hero) {
            HStack(alignment: .top, spacing: ODSpacing.lg) {
                VStack(alignment: .leading, spacing: ODSpacing.xs) {
                    Text("Smart Categories")
                        .odTextStyle(.display)
                        .accessibilityIdentifier("smart_categories_title")
                    Text("Intent-driven cleanup categories with explicit safety tiers and reclaim impact.")
                        .odTextStyle(.body, color: .textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: ODSpacing.sm) {
                    if viewModel.state.usedCachedResults {
                        Text("Source: Cached")
                            .odTextStyle(.caption, color: .review)
                    } else {
                        Text("Source: Live")
                            .odTextStyle(.caption, color: .safe)
                    }

                    Button("Quick Clean Safe") {
                        Task {
                            await viewModel.executeQuickClean()
                        }
                    }
                    .buttonStyle(ActionButtonStyle(variant: .primary))
                    .disabled(viewModel.isExecutingQuickClean || viewModel.totalSafeCleanupBytes <= 0)
                    .accessibilityIdentifier("smart_categories_quick_clean_button")
                }
            }
        }
    }

    private var summaryCards: some View {
        HStack(spacing: ODSpacing.md) {
            StatCard(
                title: "Safe Cleanup",
                value: Formatting.bytes(viewModel.totalSafeCleanupBytes),
                subtitle: "Low-risk reclaim",
                icon: "checkmark.shield",
                iconColor: ODColors.safe
            )

            StatCard(
                title: "Review Cleanup",
                value: Formatting.bytes(viewModel.totalReviewCleanupBytes),
                subtitle: "Needs verification",
                icon: "exclamationmark.triangle",
                iconColor: ODColors.review
            )

            StatCard(
                title: "Categories",
                value: "\(viewModel.state.categories.count)",
                subtitle: "Coverage areas",
                icon: "square.stack.3d.up",
                iconColor: ODColors.accentSecondary
            )
        }
    }

    private var categoriesPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: ODSpacing.sm) {
                Text("Category Breakdown")
                    .odTextStyle(.heading)

                if viewModel.state.categories.isEmpty {
                    EmptyState(
                        icon: "square.stack.3d.up",
                        message: "No category data",
                        detail: "Run a refresh scan to populate category insights."
                    )
                    .frame(minHeight: 240)
                } else {
                    ForEach(Array(viewModel.state.categories.enumerated()), id: \.element.id) { index, category in
                        AnimatedListRow(index: index) {
                            VStack(alignment: .leading, spacing: ODSpacing.sm) {
                                HStack(spacing: ODSpacing.sm) {
                                    Image(systemName: category.kind.systemImage)
                                        .odIcon(.small)
                                        .odForeground(.accent)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(category.kind.title)
                                            .odTextStyle(.body)
                                        Text("\(category.itemCount) items")
                                            .odTextStyle(.caption, color: .textSecondary)
                                    }

                                    Spacer()

                                    SizeBadge(bytes: category.totalBytes)
                                }

                                riskBreakdown(for: category)
                            }
                            .odSurfaceCard(selected: false)
                        }
                    }
                }

                if let result = viewModel.quickCleanResult {
                    HStack(spacing: ODSpacing.sm) {
                        Image(systemName: result.failures.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .odIcon(.small)
                            .odForeground(result.failures.isEmpty ? .safe : .review)
                        Text(
                            result.failures.isEmpty
                                ? "Quick clean reclaimed \(Formatting.bytes(result.reclaimedBytes))."
                                : "Quick clean completed with \(result.failures.count) issues."
                        )
                        .odTextStyle(.caption, color: .textSecondary)
                    }
                    .accessibilityIdentifier("smart_categories_quick_clean_result")
                }
            }
        }
    }

    private func riskBreakdown(for category: SmartCategory) -> some View {
        let safe = Double(category.safeCleanupBytes)
        let review = Double(category.reviewCleanupBytes)
        let risky = Double(category.riskyCleanupBytes)
        let total = max(1, safe + review + risky)

        return VStack(alignment: .leading, spacing: ODSpacing.xs) {
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(ODColors.safe.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .frame(width: CGFloat(safe / total) * 280)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(ODColors.review.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .frame(width: CGFloat(review / total) * 280)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(ODColors.risky.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .frame(width: CGFloat(risky / total) * 280)
            }
            .frame(height: 8)
            .clipShape(Capsule())

            HStack(spacing: ODSpacing.md) {
                legendLabel(title: "Safe", bytes: category.safeCleanupBytes, color: .safe)
                legendLabel(title: "Review", bytes: category.reviewCleanupBytes, color: .review)
                legendLabel(title: "Risky", bytes: category.riskyCleanupBytes, color: .risky)
            }
        }
    }

    private func legendLabel(title: String, bytes: Int64, color: ODColorToken) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color.color)
                .frame(width: 6, height: 6)
            Text("\(title) \(Formatting.bytes(bytes))")
                .odTextStyle(.caption, color: .textSecondary)
        }
    }
}
