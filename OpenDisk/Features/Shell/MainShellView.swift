import SwiftUI

struct MainShellView: View {
    @ObservedObject var rootViewModel: RootViewModel
    @Namespace private var sidebarAnimation
    @State private var isRefreshing = false
    private let isRunningUnderTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().opacity(0.3)
            detailArea
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        isRefreshing = true
                        await rootViewModel.refreshAll()
                        isRefreshing = false
                    }
                } label: {
                    HStack(spacing: ODSpacing.xs) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(
                                isRefreshing
                                    ? .linear(duration: 1.0).repeatForever(autoreverses: false)
                                    : .default,
                                value: isRefreshing
                            )
                        Text("Refresh")
                    }
                }
                .buttonStyle(ActionButtonStyle(variant: .secondary))
            }
        }
        .overlay(alignment: .bottom) {
            statusFooter
        }
        .task {
            guard !isRunningUnderTests else { return }
            await rootViewModel.refreshAll()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            // App title
            HStack(spacing: ODSpacing.sm) {
                Image(systemName: "externaldrive.fill")
                    .odIcon(.regular)
                    .foregroundStyle(ODColors.accent)
                Text("OpenDisk")
                    .odTextStyle(.heading)
                    .foregroundStyle(ODColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, ODSpacing.lg)
            .padding(.top, ODSpacing.lg)
            .padding(.bottom, ODSpacing.md)

            Divider().opacity(0.2).padding(.horizontal, ODSpacing.md)

            // Nav items
            ScrollView {
                VStack(spacing: ODSpacing.xs) {
                    ForEach(Array(AppSection.allCases.enumerated()), id: \.element.id) { index, section in
                        sidebarItem(section, index: index)
                    }
                }
                .padding(.horizontal, ODSpacing.md)
                .padding(.vertical, ODSpacing.sm)
            }

            Spacer()

            // Disk usage mini-bar
            diskUsageBar
                .padding(.horizontal, ODSpacing.md)
                .padding(.bottom, ODSpacing.md)
        }
        .frame(width: 240)
        .background(
            NativeGlassSurface(cornerRadius: 0, tint: ODColors.accent.opacity(0.04), material: .sidebarGlass)
        )
    }

    private func sidebarItem(_ section: AppSection, index: Int) -> some View {
        HStack(spacing: ODSpacing.sm) {
            ZStack {
                Circle()
                    .fill(sectionTint(section).opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: section.systemImage)
                    .odIcon(.small)
                    .foregroundStyle(sectionTint(section))
            }

            Text(section.title)
                .odTextStyle(.body)
                .foregroundStyle(ODColors.textPrimary)

            Spacer()
        }
        .padding(.horizontal, ODSpacing.sm)
        .padding(.vertical, ODSpacing.sm)
        .background(
            Group {
                if rootViewModel.selectedSection == section {
                    RoundedRectangle(cornerRadius: ODRadius.sm, style: .continuous)
                        .fill(ODColors.insetSurfaceSelected)
                        .matchedGeometryEffect(id: "sidebar_selection", in: sidebarAnimation)
                }
            }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(ODAnimation.snappy) {
                rootViewModel.selectedSection = section
            }
        }
        .accessibilityIdentifier("sidebar_\(section.rawValue)")
    }

    private func sectionTint(_ section: AppSection) -> Color {
        switch section {
        case .appManager: return ODColors.accent
        case .recommendations: return .purple
        case .storageMap: return .orange
        case .smartCategories: return .teal
        case .duplicates: return .pink
        case .timeline: return ODColors.safe
        }
    }

    private var diskUsageBar: some View {
        VStack(alignment: .leading, spacing: ODSpacing.xs) {
            HStack {
                Text("Storage")
                    .odTextStyle(.caption)
                    .foregroundStyle(ODColors.textSecondary)
                Spacer()
                Text("\(rootViewModel.appManagerViewModel.state.apps.count) apps")
                    .odTextStyle(.caption)
                    .foregroundStyle(ODColors.textSecondary)
            }

            GeometryReader { geo in
                let reclaimRatio = min(1.0, Double(rootViewModel.appManagerViewModel.totalReclaimPotential) / max(1, Double(rootViewModel.appManagerViewModel.totalReclaimPotential) * 3))
                HStack(spacing: 1) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ODColors.accent.opacity(0.6))
                        .frame(width: geo.size.width * CGFloat(1.0 - reclaimRatio))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ODColors.review.opacity(0.5))
                        .frame(width: max(0, geo.size.width * CGFloat(reclaimRatio)))
                }
            }
            .frame(height: 6)
            .clipShape(Capsule())
        }
        .padding(ODSpacing.sm)
        .background(ODColors.insetSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: ODRadius.sm, style: .continuous))
    }

    // MARK: - Detail Area

    private var detailArea: some View {
        ZStack {
            detailView
                .id(rootViewModel.selectedSection)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(x: 0, y: 8)),
                    removal: .opacity
                ))
        }
        .animation(ODAnimation.pageTransition, value: rootViewModel.selectedSection)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var detailView: some View {
        switch rootViewModel.selectedSection {
        case .appManager:
            AppManagerView(viewModel: rootViewModel.appManagerViewModel)
        case .recommendations:
            RecommendationsView(viewModel: rootViewModel.recommendationsViewModel)
        case .timeline:
            ActivityMonitorView(viewModel: rootViewModel.activityMonitorViewModel)
        case .storageMap, .smartCategories, .duplicates:
            EmptyState(
                icon: "hammer.fill",
                message: rootViewModel.selectedSection.title,
                detail: "Planned in subsequent milestones. Foundation and uninstaller-first flow are live."
            )
            .odCanvasBackground()
        }
    }

    // MARK: - Status Footer

    private var statusFooter: some View {
        HStack(spacing: ODSpacing.lg) {
            statusPill(icon: "square.grid.2x2", text: "\(rootViewModel.appManagerViewModel.state.apps.count) Apps")
            statusPill(icon: "arrow.down.circle", text: Formatting.bytes(rootViewModel.appManagerViewModel.totalReclaimPotential))
            statusPill(
                icon: "cylinder.split.1x2",
                text: rootViewModel.appManagerViewModel.state.usedCachedResults ? "Cached" : "Live"
            )
            statusPill(
                icon: "sparkles",
                text: rootViewModel.recommendationsViewModel.state.usedCachedResults ? "AI: Cached" : "AI: Live"
            )
            statusPill(icon: "scope", text: rootViewModel.scanScope.title)
        }
        .padding(.horizontal, ODSpacing.lg)
        .padding(.vertical, ODSpacing.sm)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(ODColors.glassBorderSubtle, lineWidth: 0.5))
                .shadow(color: ODColors.shadowSubtle, radius: 12, y: 4)
        )
        .padding(.bottom, ODSpacing.sm)
    }

    private func statusPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .odIcon(.tiny)
            Text(text)
                .contentTransition(.numericText())
        }
        .odTextStyle(.caption)
        .foregroundStyle(ODColors.textSecondary)
    }
}
