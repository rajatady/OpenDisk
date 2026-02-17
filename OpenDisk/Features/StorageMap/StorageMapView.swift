import SwiftUI

struct StorageMapView: View {
    @ObservedObject var viewModel: StorageMapViewModel
    let scope: ScanScope

    @State private var stack: [DiskNode] = []

    private var palette: [Color] {
        [ODColors.accent, ODColors.accentSecondary, ODColors.safe, ODColors.review, ODColors.risky]
    }

    private var currentNode: DiskNode? {
        stack.last ?? viewModel.state.root
    }

    var body: some View {
        VStack(spacing: ODSpacing.md) {
            header
            statsRow
            mapPanel
            topNodesPanel
        }
        .padding(ODSpacing.lg)
        .odCanvasBackground()
        .task {
            await loadIfNeeded()
        }
        .onChange(of: viewModel.state.root?.id) { _, _ in
            guard let root = viewModel.state.root else { return }
            if stack.first?.id != root.id {
                stack = [root]
            }
        }
    }

    private var header: some View {
        GlassPanel(style: .hero) {
            HStack(alignment: .top, spacing: ODSpacing.lg) {
                VStack(alignment: .leading, spacing: ODSpacing.xs) {
                    Text("Storage Map")
                        .odTextStyle(.display)
                        .accessibilityIdentifier("storage_map_title")
                    Text("Visualize where disk space lives, drill down by directory, and keep scans fast with caching.")
                        .odTextStyle(.body, color: .textSecondary)
                    breadcrumb
                }

                Spacer()

                VStack(alignment: .trailing, spacing: ODSpacing.sm) {
                    HStack(spacing: ODSpacing.xs) {
                        Button {
                            withAnimation(ODAnimation.snappy) {
                                _ = stack.popLast()
                            }
                        } label: {
                            HStack(spacing: ODSpacing.xs) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                        .buttonStyle(ActionButtonStyle(variant: .secondary))
                        .disabled(stack.count <= 1)
                        .accessibilityIdentifier("storage_map_back_button")

                        Button("Root") {
                            guard let root = viewModel.state.root else { return }
                            withAnimation(ODAnimation.snappy) {
                                stack = [root]
                            }
                        }
                        .buttonStyle(ActionButtonStyle(variant: .secondary))
                        .disabled(stack.count <= 1)
                        .accessibilityIdentifier("storage_map_root_button")
                    }

                    if let lastScanAt = viewModel.state.lastScanAt {
                        Text("Updated \(Formatting.relativeDate(lastScanAt))")
                            .odTextStyle(.caption, color: .textSecondary)
                    }
                    Button("Rescan") {
                        Task {
                            await viewModel.load(scope: scope, forceRefresh: true)
                        }
                    }
                    .buttonStyle(ActionButtonStyle(variant: .secondary))
                    .accessibilityIdentifier("storage_map_rescan_button")
                }
            }
        }
    }

    private var breadcrumb: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ODSpacing.xs) {
                ForEach(Array(stack.enumerated()), id: \.element.id) { index, node in
                    Button {
                        withAnimation(ODAnimation.snappy) {
                            stack = Array(stack.prefix(index + 1))
                        }
                    } label: {
                        Text(node.name.isEmpty ? "/" : node.name)
                            .odTextStyle(.caption, color: index == stack.count - 1 ? .textPrimary : .textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .buttonStyle(.plain)

                    if index < stack.count - 1 {
                        Image(systemName: "chevron.right")
                            .odIcon(.tiny)
                            .odForeground(.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statsRow: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 220), spacing: ODSpacing.md)],
            spacing: ODSpacing.md
        ) {
            StatCard(
                title: "Current Node",
                value: currentNode?.name.isEmpty == false ? (currentNode?.name ?? "/") : "/",
                subtitle: currentNode?.path ?? scope.title,
                icon: "folder",
                iconColor: ODColors.accent
            )

            StatCard(
                title: "Visible Size",
                value: Formatting.bytes(currentNode?.sizeBytes ?? 0),
                subtitle: viewModel.state.usedCachedResults ? "Cached scan" : "Live scan",
                icon: "internaldrive",
                iconColor: viewModel.state.usedCachedResults ? ODColors.review : ODColors.safe
            )

            StatCard(
                title: "Child Nodes",
                value: "\(currentNode?.children.count ?? 0)",
                subtitle: "Top directories/files in view",
                icon: "square.split.2x2",
                iconColor: ODColors.accentSecondary
            )
        }
    }

    private var mapPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: ODSpacing.sm) {
                HStack {
                    Text("Treemap")
                        .odTextStyle(.heading)
                    Spacer()
                    if viewModel.state.usedCachedResults {
                        Text("Cached")
                            .odTextStyle(.caption, color: .review)
                    } else {
                        Text("Live")
                            .odTextStyle(.caption, color: .safe)
                    }
                }

                if viewModel.state.isLoading {
                    VStack(spacing: ODSpacing.md) {
                        ProgressRing(progress: viewModel.state.scanProgress, lineWidth: 5, size: 56)
                        ODInlineProgressView(label: viewModel.state.scanMessage, progress: viewModel.state.scanProgress)
                            .frame(maxWidth: 320)
                    }
                    .frame(maxWidth: .infinity, minHeight: 260)
                } else if let errorMessage = viewModel.state.errorMessage {
                    EmptyState(
                        icon: "exclamationmark.triangle",
                        message: "Storage map failed",
                        detail: errorMessage,
                        actionTitle: "Retry",
                        action: {
                            Task {
                                await viewModel.load(scope: scope, forceRefresh: true)
                            }
                        }
                    )
                    .frame(minHeight: 260)
                } else if let node = currentNode, !node.children.isEmpty {
                    treemap(for: node)
                        .frame(minHeight: 260)
                } else {
                    EmptyState(
                        icon: "folder",
                        message: "No children to render",
                        detail: "This node has no nested directories in the current scan depth."
                    )
                    .frame(minHeight: 260)
                }
            }
        }
        .overlay(
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("storage_map_chart")
        )
    }

    private func treemap(for node: DiskNode) -> some View {
        GeometryReader { geo in
            let items = Array(node.children.prefix(12))
            let total = max(1, items.reduce(0) { $0 + $1.sizeBytes })

            HStack(spacing: ODSpacing.xs) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, child in
                    let widthFraction = CGFloat(Double(child.sizeBytes) / Double(total))
                    let canDrillDown = !child.children.isEmpty

                    Button {
                        guard canDrillDown else { return }
                        withAnimation(ODAnimation.pageTransition) {
                            stack.append(child)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: ODSpacing.xs) {
                            Text(child.name)
                                .odTextStyle(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(Formatting.bytes(child.sizeBytes))
                                .odTextStyle(.caption, color: .textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(ODSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: ODRadius.md, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [tileTint(index).opacity(0.30), ODColors.insetSurface.opacity(0.82)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: ODRadius.md, style: .continuous)
                                .stroke(ODColors.glassBorderSubtle, lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canDrillDown)
                    .frame(width: max(geo.size.width * widthFraction, 40))
                    .accessibilityIdentifier("storage_map_tile_\(index)")
                }
            }
        }
    }

    private var topNodesPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: ODSpacing.sm) {
                Text("Top Nodes")
                    .odTextStyle(.heading)

                if let node = currentNode {
                    let items = Array(node.children.prefix(8))
                    if items.isEmpty {
                        Text("No children available in the selected node.")
                            .odTextStyle(.body, color: .textSecondary)
                    } else {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, child in
                            let canDrillDown = !child.children.isEmpty
                            Button {
                                guard canDrillDown else { return }
                                withAnimation(ODAnimation.snappy) {
                                    stack.append(child)
                                }
                            } label: {
                                AnimatedListRow(index: index, animateEntry: index < 20, enableHover: canDrillDown) {
                                    HStack(spacing: ODSpacing.sm) {
                                        Image(systemName: child.isDirectory ? "folder.fill" : "doc")
                                            .odIcon(.small)
                                            .odForeground(.textSecondary)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(child.name)
                                                .odTextStyle(.body)
                                                .lineLimit(1)
                                            Text(child.path)
                                                .odTextStyle(.caption, color: .textSecondary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                        }
                                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                                        if canDrillDown {
                                            Image(systemName: "chevron.right")
                                                .odIcon(.caption)
                                                .odForeground(.textSecondary)
                                        }

                                        SizeBadge(bytes: child.sizeBytes)
                                    }
                                    .odSurfaceCard(selected: false)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(!canDrillDown)
                            .accessibilityIdentifier("storage_map_node_\(index)")
                        }
                    }
                }
            }
        }
    }

    private func tileTint(_ index: Int) -> Color {
        palette[index % palette.count]
    }

    private func loadIfNeeded() async {
        if viewModel.state.root == nil {
            await viewModel.load(scope: scope)
        }
    }
}
