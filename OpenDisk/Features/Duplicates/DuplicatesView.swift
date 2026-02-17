import SwiftUI

struct DuplicatesView: View {
    @ObservedObject var viewModel: DuplicatesViewModel

    var body: some View {
        VStack(spacing: ODSpacing.md) {
            header
            summaryCards
            contentPanels
        }
        .padding(ODSpacing.lg)
        .odCanvasBackground()
    }

    private var header: some View {
        GlassPanel(style: .hero) {
            HStack(alignment: .top, spacing: ODSpacing.lg) {
                VStack(alignment: .leading, spacing: ODSpacing.xs) {
                    Text("Large Files & Duplicates")
                        .odTextStyle(.display)
                        .accessibilityIdentifier("duplicates_title")
                    Text("Prioritize high-impact cleanup by surfacing oversized entries and duplicate clusters.")
                        .odTextStyle(.body, color: .textSecondary)
                }
                Spacer()
                Text(viewModel.state.usedCachedResults ? "Source: Cached" : "Source: Live")
                    .odTextStyle(.caption, color: viewModel.state.usedCachedResults ? .review : .safe)
            }
        }
    }

    private var summaryCards: some View {
        HStack(spacing: ODSpacing.md) {
            StatCard(
                title: "Duplicate Groups",
                value: "\(viewModel.state.duplicateGroups.count)",
                subtitle: "Potential overlap clusters",
                icon: "doc.on.doc",
                iconColor: ODColors.review
            )

            StatCard(
                title: "Potential Reclaim",
                value: Formatting.bytes(viewModel.potentialDuplicateReclaim),
                subtitle: "If one copy is kept per group",
                icon: "arrow.down.circle",
                iconColor: ODColors.safe
            )

            StatCard(
                title: "Largest Item",
                value: Formatting.bytes(viewModel.state.largeItems.first?.sizeBytes ?? 0),
                subtitle: viewModel.state.largeItems.first?.title ?? "N/A",
                icon: "arrow.up.right.square",
                iconColor: ODColors.accent
            )
        }
    }

    private var contentPanels: some View {
        HStack(alignment: .top, spacing: ODSpacing.md) {
            duplicateGroupsPanel
            largeItemsPanel
        }
    }

    private var duplicateGroupsPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: ODSpacing.sm) {
                Text("Duplicate Groups")
                    .odTextStyle(.heading)

                if viewModel.state.duplicateGroups.isEmpty {
                    Text("No duplicate groups detected in the current dataset.")
                        .odTextStyle(.body, color: .textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
                } else {
                    ForEach(Array(viewModel.state.duplicateGroups.enumerated()), id: \.element.id) { index, group in
                        AnimatedListRow(index: index) {
                            VStack(alignment: .leading, spacing: ODSpacing.xs) {
                                HStack(spacing: ODSpacing.sm) {
                                    Text(group.name)
                                        .odTextStyle(.body)
                                        .lineLimit(1)
                                    Spacer()
                                    SizeBadge(bytes: group.totalBytes, level: .review)
                                }
                                Text("\(group.duplicates.count) entries")
                                    .odTextStyle(.caption, color: .textSecondary)

                                ForEach(group.duplicates.prefix(3)) { duplicate in
                                    Text(duplicate.path)
                                        .odTextStyle(.caption, color: .textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            .odSurfaceCard(selected: false)
                        }
                    }
                }
            }
        }
    }

    private var largeItemsPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: ODSpacing.sm) {
                Text("Largest Items")
                    .odTextStyle(.heading)

                if viewModel.state.largeItems.isEmpty {
                    Text("No large items available.")
                        .odTextStyle(.body, color: .textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
                } else {
                    ForEach(Array(viewModel.state.largeItems.enumerated()), id: \.element.id) { index, item in
                        AnimatedListRow(index: index) {
                            HStack(spacing: ODSpacing.sm) {
                                Image(systemName: item.isDirectory ? "folder.fill" : "doc")
                                    .odIcon(.small)
                                    .odForeground(.textSecondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .odTextStyle(.body)
                                        .lineLimit(1)
                                    Text(item.path)
                                        .odTextStyle(.caption, color: .textSecondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                SizeBadge(bytes: item.sizeBytes)
                            }
                            .odSurfaceCard(selected: false)
                        }
                    }
                }
            }
        }
    }
}
