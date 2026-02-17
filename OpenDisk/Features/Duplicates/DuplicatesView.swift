import SwiftUI

struct DuplicatesView: View {
    @ObservedObject var viewModel: DuplicatesViewModel
    @State private var duplicateDisplayLimit = 40
    @State private var largeItemDisplayLimit = 80

    private var displayedDuplicateGroups: [DuplicateGroup] {
        Array(viewModel.state.duplicateGroups.prefix(duplicateDisplayLimit))
    }

    private var displayedLargeItems: [LargeItem] {
        Array(viewModel.state.largeItems.prefix(largeItemDisplayLimit))
    }

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
                    Text("Prioritize high-impact cleanup by surfacing oversized entries and duplicate clusters, with overflow-safe traversal.")
                        .odTextStyle(.body, color: .textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: ODSpacing.xs) {
                    Text(viewModel.state.usedCachedResults ? "Source: Cached" : "Source: Live")
                        .odTextStyle(.caption, color: viewModel.state.usedCachedResults ? .review : .safe)
                    Text("Grouping is heuristic; verify before cleanup.")
                        .odTextStyle(.caption, color: .textSecondary)
                }
            }
        }
    }

    private var summaryCards: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 220), spacing: ODSpacing.md)],
            spacing: ODSpacing.md
        ) {
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
        GeometryReader { geometry in
            Group {
                if geometry.size.width < 980 {
                    VStack(alignment: .leading, spacing: ODSpacing.md) {
                        duplicateGroupsPanel
                        largeItemsPanel
                    }
                } else {
                    HStack(alignment: .top, spacing: ODSpacing.md) {
                        duplicateGroupsPanel
                        largeItemsPanel
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minHeight: 520)
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
                    ScrollView {
                        LazyVStack(spacing: ODSpacing.xs) {
                            ForEach(Array(displayedDuplicateGroups.enumerated()), id: \.element.id) { index, group in
                                AnimatedListRow(index: index, animateEntry: index < 24, enableHover: index < 180) {
                                    VStack(alignment: .leading, spacing: ODSpacing.xs) {
                                        HStack(spacing: ODSpacing.sm) {
                                            Text(group.name)
                                                .odTextStyle(.body)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            SizeBadge(bytes: group.totalBytes, level: .review)
                                        }
                                        Text("\(group.duplicates.count) entries")
                                            .odTextStyle(.caption, color: .textSecondary)

                                        ForEach(group.duplicates.prefix(3)) { duplicate in
                                            Text(duplicate.path)
                                                .odTextStyle(.caption, color: .textSecondary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    .odSurfaceCard(selected: false)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)

                    if displayedDuplicateGroups.count < viewModel.state.duplicateGroups.count {
                        Button {
                            duplicateDisplayLimit += 40
                        } label: {
                            Text("Show More Groups (\(viewModel.state.duplicateGroups.count - displayedDuplicateGroups.count) remaining)")
                        }
                        .buttonStyle(ActionButtonStyle(variant: .secondary))
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
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
                    ScrollView {
                        LazyVStack(spacing: ODSpacing.xs) {
                            ForEach(Array(displayedLargeItems.enumerated()), id: \.element.id) { index, item in
                                AnimatedListRow(index: index, animateEntry: index < 30, enableHover: index < 220) {
                                    HStack(spacing: ODSpacing.sm) {
                                        Image(systemName: item.isDirectory ? "folder.fill" : "doc")
                                            .odIcon(.small)
                                            .odForeground(.textSecondary)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title)
                                                .odTextStyle(.body)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                            Text(item.path)
                                                .odTextStyle(.caption, color: .textSecondary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                        }
                                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                        SizeBadge(bytes: item.sizeBytes)
                                    }
                                    .odSurfaceCard(selected: false)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)

                    if displayedLargeItems.count < viewModel.state.largeItems.count {
                        Button {
                            largeItemDisplayLimit += 60
                        } label: {
                            Text("Show More Items (\(viewModel.state.largeItems.count - displayedLargeItems.count) remaining)")
                        }
                        .buttonStyle(ActionButtonStyle(variant: .secondary))
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
