import SwiftUI

private enum AppIconProvider {
    private static let cache = NSCache<NSString, NSImage>()

    static func icon(for path: String) -> NSImage {
        let key = path as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: 64, height: 64)
        cache.setObject(icon, forKey: key)
        return icon
    }
}

struct AppManagerView: View {
    enum DisplayMode: String, CaseIterable, Identifiable {
        case list
        case grid

        var id: String { rawValue }
    }

    @ObservedObject var viewModel: AppManagerViewModel
    @State private var displayMode: DisplayMode = .list
    @State private var showUninstallSheet = false

    var body: some View {
        VStack(spacing: ODSpacing.md) {
            heroBanner
            topStats
            content
        }
        .padding(ODSpacing.lg)
        .odCanvasBackground()
        .task {
            if viewModel.state.apps.isEmpty {
                await viewModel.loadApps()
            }
        }
        .sheet(isPresented: $showUninstallSheet) {
            uninstallSheet
                .padding(ODSpacing.lg)
                .frame(width: 540)
        }
    }

    // MARK: - Hero Banner

    private var heroBanner: some View {
        GlassPanel(style: .hero) {
            HStack(spacing: ODSpacing.lg) {
                VStack(alignment: .leading, spacing: ODSpacing.sm) {
                    Text("Disk Command Center")
                        .odTextStyle(.display)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ODColors.textPrimary, ODColors.textPrimary.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Precision uninstall intelligence with profile-aware cleanup guidance.")
                        .odTextStyle(.body, color: .textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: ODSpacing.sm) {
                    HStack(spacing: ODSpacing.xs) {
                        Circle()
                            .fill(viewModel.state.isLoading ? ODColors.review : ODColors.safe)
                            .frame(width: 7, height: 7)
                        Text(viewModel.state.scanMessage.isEmpty ? "Idle" : viewModel.state.scanMessage)
                            .odTextStyle(.caption, color: .textSecondary)
                    }

                    if viewModel.state.usedCachedResults {
                        HStack(spacing: ODSpacing.xs) {
                            Image(systemName: "cylinder.split.1x2.fill")
                                .odIcon(.tiny)
                            Text("Using cached catalog")
                        }
                        .odTextStyle(.caption, color: .safe)
                    }

                    if let progress = viewModel.state.scanProgress, viewModel.state.isLoading {
                        ProgressView(value: progress)
                            .frame(width: 180)
                            .tint(ODColors.accent)
                    }
                }
            }
        }
    }

    // MARK: - Stats

    private var topStats: some View {
        HStack(spacing: ODSpacing.md) {
            StatCard(
                title: "Installed Apps",
                value: "\(viewModel.state.apps.count)",
                subtitle: "With true-size calculation",
                icon: "square.grid.2x2.fill",
                iconColor: ODColors.accent
            )
            StatCard(
                title: "Reclaim Potential",
                value: Formatting.bytes(viewModel.totalReclaimPotential),
                subtitle: "Support files + caches",
                icon: "arrow.down.circle.fill",
                iconColor: ODColors.review
            )
        }
    }

    // MARK: - Content

    private var content: some View {
        HStack(spacing: ODSpacing.md) {
            GlassPanel {
                VStack(spacing: ODSpacing.md) {
                    HStack {
                        TextField("Search apps", text: $viewModel.searchText)
                            .textFieldStyle(ODInputFieldStyle())
                            .accessibilityIdentifier("app_search_field")

                        Picker("Sort", selection: $viewModel.sortOrder) {
                            ForEach(AppManagerViewModel.SortOrder.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Mode", selection: $displayMode) {
                            Image(systemName: "list.bullet").tag(DisplayMode.list)
                            Image(systemName: "square.grid.2x2").tag(DisplayMode.grid)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }

                    if viewModel.state.isLoading {
                        VStack(spacing: ODSpacing.lg) {
                            ProgressRing(progress: viewModel.state.scanProgress, lineWidth: 4, size: 48)
                            Text(viewModel.state.scanMessage.isEmpty ? "Scanning apps..." : viewModel.state.scanMessage)
                                .odTextStyle(.caption, color: .textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.state.errorMessage {
                        EmptyState(
                            icon: "exclamationmark.triangle",
                            message: "Error",
                            detail: error
                        )
                    } else {
                        appCollection
                    }
                }
                .frame(minWidth: 430, maxHeight: .infinity, alignment: .top)
            }

            GlassPanel {
                detailsPane
                    .frame(minWidth: 420, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .animation(ODAnimation.smooth, value: viewModel.state.filteredApps)
    }

    // MARK: - App Collection

    @ViewBuilder
    private var appCollection: some View {
        if displayMode == .list {
            List(selection: $viewModel.selectedAppID) {
                ForEach(viewModel.state.filteredApps, id: \.id) { app in
                    Button {
                        withAnimation(ODAnimation.snappy) {
                            viewModel.selectedAppID = app.id
                        }
                    } label: {
                        HStack(spacing: ODSpacing.md) {
                            appIcon(for: app)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.displayName)
                                    .odTextStyle(.heading)
                                    .lineLimit(1)
                                HStack(spacing: ODSpacing.xs) {
                                    Text(app.bundleID)
                                        .odTextStyle(.caption, color: .textSecondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    if let lastUsed = app.lastUsedDate {
                                        Text("·")
                                            .odTextStyle(.caption, color: .textSecondary)
                                        Text(Formatting.relativeDate(lastUsed))
                                            .odTextStyle(.caption, color: .textSecondary)
                                    }
                                }
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            }
                            Spacer()
                            SizeBadge(bytes: app.trueSizeBytes)
                        }
                        .odSurfaceCard(selected: viewModel.selectedAppID == app.id)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("app_row_\(app.bundleID)")
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: ODSpacing.sm)], spacing: ODSpacing.sm) {
                    ForEach(Array(viewModel.state.filteredApps.enumerated()), id: \.element.id) { index, app in
                        Button {
                            withAnimation(ODAnimation.snappy) {
                                viewModel.selectedAppID = app.id
                            }
                        } label: {
                            HoverCard {
                                VStack(alignment: .leading, spacing: ODSpacing.sm) {
                                    HStack {
                                        appIcon(for: app)
                                        Spacer()
                                        SizeBadge(bytes: app.trueSizeBytes)
                                    }
                                    Text(app.displayName)
                                        .odTextStyle(.heading)
                                    Text(Formatting.relativeDate(app.lastUsedDate))
                                        .odTextStyle(.caption, color: .textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .odSurfaceCard(selected: viewModel.selectedAppID == app.id)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, ODSpacing.xs)
            }
        }
    }

    private func appIcon(for app: InstalledApp) -> some View {
        Group {
            let icon = AppIconProvider.icon(for: app.bundlePath)
            Image(nsImage: icon)
                .resizable()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .shadow(color: ODColors.shadowSubtle, radius: 3, y: 1)
        }
    }

    // MARK: - Detail Pane

    @ViewBuilder
    private var detailsPane: some View {
        if let app = viewModel.selectedApp {
            ScrollView {
                VStack(alignment: .leading, spacing: ODSpacing.md) {
                    // App header
                    HStack(spacing: ODSpacing.md) {
                        let icon = AppIconProvider.icon(for: app.bundlePath)
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: ODColors.shadow, radius: 12, y: 6)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(app.displayName)
                                .odTextStyle(.title)
                            Text(app.bundleID)
                                .odTextStyle(.caption, color: .textSecondary)
                        }
                        Spacer()
                        SizeBadge(bytes: app.trueSizeBytes)
                    }

                    // Size breakdown bar
                    if !app.groupedArtifacts.isEmpty {
                        sizeBreakdownBar(app: app)
                    }

                    SectionHeader(icon: "folder.fill", title: "Artifact Breakdown", subtitle: "\(app.artifacts.count) items found")

                    // Artifact groups
                    ForEach(app.groupedArtifacts) { group in
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: ODSpacing.xs) {
                                ForEach(group.artifacts.prefix(6)) { artifact in
                                    HStack(alignment: .top, spacing: ODSpacing.sm) {
                                        Image(systemName: artifact.isDirectory ? "folder.fill" : "doc.fill")
                                            .odIcon(.small)
                                            .foregroundStyle(ODColors.textSecondary.opacity(0.6))
                                            .frame(width: 16)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(artifact.url.lastPathComponent)
                                                .odTextStyle(.body)
                                            Text(artifact.path)
                                                .odTextStyle(.mono)
                                                .foregroundStyle(ODColors.textSecondary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                        }
                                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                        Spacer()
                                        SizeBadge(bytes: artifact.sizeBytes)
                                    }
                                }
                            }
                            .padding(.top, ODSpacing.xs)
                        } label: {
                            HStack {
                                Text(group.kind.rawValue)
                                    .odTextStyle(.heading)
                                Spacer()
                                SafetyLabel(level: group.artifacts.first?.safetyLevel ?? .review)
                                SizeBadge(bytes: group.totalBytes)
                            }
                        }
                        .padding(ODSpacing.sm)
                        .background(ODColors.insetSurface.opacity(0.4), in: RoundedRectangle(cornerRadius: ODRadius.md, style: .continuous))
                    }

                    // Action buttons
                    HStack(spacing: ODSpacing.sm) {
                        Button {
                            viewModel.createPlan(mode: .removeEverything)
                            showUninstallSheet = true
                        } label: {
                            HStack(spacing: ODSpacing.xs) {
                                Image(systemName: "trash.fill")
                                Text("Remove Everything")
                            }
                        }
                        .buttonStyle(ActionButtonStyle(variant: .destructive))
                        .accessibilityIdentifier("uninstall_button")

                        Button {
                            viewModel.createPlan(mode: .keepUserData)
                            showUninstallSheet = true
                        } label: {
                            HStack(spacing: ODSpacing.xs) {
                                Image(systemName: "person.crop.circle")
                                Text("Keep User Data")
                            }
                        }
                        .buttonStyle(ActionButtonStyle(variant: .secondary))
                    }

                    Divider().opacity(0.3)

                    // Orphans
                    SectionHeader(
                        icon: "questionmark.folder.fill",
                        title: "Orphan Data",
                        trailing: AnyView(
                            Button {
                                Task { await viewModel.refreshOrphans() }
                            } label: {
                                HStack(spacing: ODSpacing.xs) {
                                    Image(systemName: "magnifyingglass")
                                    Text("Scan")
                                }
                            }
                            .buttonStyle(ActionButtonStyle(variant: .secondary))
                            .accessibilityIdentifier("scan_orphans_button")
                        )
                    )

                    if !viewModel.orphanArtifacts.isEmpty {
                        HStack(spacing: ODSpacing.sm) {
                            Text("\(viewModel.orphanArtifacts.count) orphan entries")
                                .odTextStyle(.body)
                            SizeBadge(bytes: viewModel.orphanArtifacts.reduce(0) { $0 + $1.sizeBytes })
                        }

                        Button {
                            Task { await viewModel.executeOrphanCleanup() }
                        } label: {
                            HStack(spacing: ODSpacing.xs) {
                                Image(systemName: "trash")
                                Text("Clean Orphans")
                            }
                        }
                        .buttonStyle(ActionButtonStyle(variant: .destructive))
                    }

                    if let result = viewModel.uninstallState.executionResult {
                        HStack(spacing: ODSpacing.sm) {
                            Image(systemName: result.failures.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(result.failures.isEmpty ? ODColors.safe : ODColors.review)
                            Text("Last cleanup reclaimed \(Formatting.bytes(result.reclaimedBytes)).")
                                .odTextStyle(.body, color: result.failures.isEmpty ? .safe : .review)
                        }
                        .padding(ODSpacing.sm)
                        .background(
                            (result.failures.isEmpty ? ODColors.safe : ODColors.review).opacity(0.08),
                            in: RoundedRectangle(cornerRadius: ODRadius.sm, style: .continuous)
                        )
                        .accessibilityIdentifier("cleanup_result_label")
                    }
                }
            }
        } else {
            EmptyState(
                icon: "square.grid.2x2",
                message: "Select an App",
                detail: "Choose an app to inspect all associated files and uninstall safely."
            )
        }
    }

    private func sizeBreakdownBar(app: InstalledApp) -> some View {
        let groups = app.groupedArtifacts
        let total = max(1, app.trueSizeBytes)

        return VStack(alignment: .leading, spacing: ODSpacing.xs) {
            GeometryReader { geo in
                HStack(spacing: 1) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ODColors.accent.opacity(0.6))
                        .frame(width: max(2, geo.size.width * CGFloat(Double(app.bundleSizeBytes) / Double(total))))

                    ForEach(groups) { group in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(artifactGroupTint(group.kind).opacity(0.5))
                            .frame(width: max(2, geo.size.width * CGFloat(Double(group.totalBytes) / Double(total))))
                    }
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())

            HStack(spacing: ODSpacing.md) {
                legendDot(color: ODColors.accent, label: "Bundle")
                ForEach(groups) { group in
                    legendDot(color: artifactGroupTint(group.kind), label: group.kind.rawValue)
                }
            }
            .odTextStyle(.caption)
            .foregroundStyle(ODColors.textSecondary)
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
        }
    }

    private func artifactGroupTint(_ kind: ArtifactGroupKind) -> Color {
        switch kind {
        case .appBundle: return ODColors.accent
        case .userData: return ODColors.accentSecondary
        case .cache: return ODColors.review
        case .preferences: return ODColors.safe
        case .systemIntegration: return ODColors.risky
        }
    }

    // MARK: - Uninstall Sheet

    private var uninstallSheet: some View {
        VStack(alignment: .leading, spacing: ODSpacing.lg) {
            HStack(spacing: ODSpacing.md) {
                ZStack {
                    Circle()
                        .fill(ODColors.risky.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "trash.fill")
                        .odIcon(.medium)
                        .foregroundStyle(ODColors.risky)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Confirm Cleanup")
                        .odTextStyle(.title)
                    if let app = viewModel.selectedApp {
                        Text(app.displayName)
                            .odTextStyle(.caption, color: .textSecondary)
                    }
                }
            }

            if let plan = viewModel.uninstallState.plan {
                HStack(spacing: ODSpacing.lg) {
                    VStack(spacing: ODSpacing.xs) {
                        AnimatedNumber("\(plan.fileCount)", font: ODTypography.title, color: ODColors.textPrimary)
                        Text("Items")
                            .odTextStyle(.caption, color: .textSecondary)
                    }
                    VStack(spacing: ODSpacing.xs) {
                        AnimatedNumber(Formatting.bytes(plan.totalBytes), font: ODTypography.title, color: ODColors.textPrimary)
                        Text("Reclaimed")
                            .odTextStyle(.caption, color: .textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(ODSpacing.md)
                .background(ODColors.insetSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: ODRadius.md, style: .continuous))
            }

            Picker("Mode", selection: Binding(get: {
                viewModel.uninstallState.selectedMode
            }, set: { newValue in
                viewModel.createPlan(mode: newValue)
            })) {
                Label("Remove Everything", systemImage: "trash.fill").tag(CleanupMode.removeEverything)
                Label("Keep User Data", systemImage: "person.crop.circle").tag(CleanupMode.keepUserData)
            }
            .pickerStyle(.segmented)

            Text("Items will be moved to Trash. You can recover them until you empty Trash.")
                .odTextStyle(.caption, color: .textSecondary)

            HStack {
                Button("Cancel") {
                    showUninstallSheet = false
                }
                .buttonStyle(ActionButtonStyle(variant: .secondary))

                Spacer()

                Button {
                    Task {
                        await viewModel.executeUninstallPlan()
                        showUninstallSheet = false
                    }
                } label: {
                    HStack(spacing: ODSpacing.xs) {
                        if viewModel.uninstallState.isExecuting {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        Text(viewModel.uninstallState.isExecuting ? "Uninstalling..." : "Confirm Cleanup")
                    }
                }
                .buttonStyle(ActionButtonStyle(variant: .destructive))
                .disabled(viewModel.uninstallState.isExecuting)
                .accessibilityIdentifier("confirm_uninstall_button")
            }
        }
    }
}
