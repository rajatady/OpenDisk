import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onCompleted: () -> Void

    @State private var animateIcon = false
    @State private var taglineVisible = false

    var body: some View {
        VStack(spacing: ODSpacing.xl) {
            // Title
            VStack(spacing: ODSpacing.xs) {
                Text("OpenDisk Setup")
                    .odTextStyle(.title)
                    .accessibilityIdentifier("onboarding_title")
                progressDots
            }

            Spacer()

            // Step content with horizontal slide
            ZStack {
                ForEach(0..<viewModel.totalSteps, id: \.self) { step in
                    if step == viewModel.state.currentStep {
                        GlassPanel(style: .elevated) {
                            stepContent(for: step)
                                .frame(maxWidth: 620, minHeight: 300, alignment: .topLeading)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                }
            }
            .animation(ODAnimation.pageTransition, value: viewModel.state.currentStep)

            // Navigation buttons
            HStack {
                if viewModel.state.currentStep > 0 {
                    Button {
                        withAnimation(ODAnimation.pageTransition) {
                            viewModel.previous()
                        }
                    } label: {
                        HStack(spacing: ODSpacing.xs) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    .buttonStyle(ActionButtonStyle(variant: .secondary))
                    .accessibilityIdentifier("onboarding_back_button")
                }

                Spacer()

                if viewModel.state.currentStep < viewModel.totalSteps - 1 {
                    Button {
                        withAnimation(ODAnimation.pageTransition) {
                            viewModel.next()
                        }
                    } label: {
                        HStack(spacing: ODSpacing.xs) {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(ActionButtonStyle(variant: .primary))
                    .disabled(!viewModel.canAdvance(from: viewModel.state.currentStep))
                    .accessibilityIdentifier("onboarding_next_button")
                } else {
                    Button {
                        viewModel.complete()
                        onCompleted()
                    } label: {
                        HStack(spacing: ODSpacing.xs) {
                            Image(systemName: "checkmark")
                            Text("Finish")
                        }
                    }
                    .buttonStyle(ActionButtonStyle(variant: .primary))
                    .disabled(!viewModel.state.canFinish)
                    .accessibilityIdentifier("onboarding_finish_button")
                }
            }
            .frame(maxWidth: 620)

            Spacer()
        }
        .padding(ODSpacing.xxl)
        .odCanvasBackground()
        .task {
            await viewModel.refreshPermissionStatus()
            viewModel.refreshAICapability()
        }
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: ODSpacing.sm) {
            ForEach(0..<viewModel.totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step == viewModel.state.currentStep ? ODColors.accent : ODColors.insetSurface)
                    .frame(width: step == viewModel.state.currentStep ? 24 : 8, height: 8)
                    .animation(ODAnimation.snappy, value: viewModel.state.currentStep)
            }
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private func stepContent(for step: Int) -> some View {
        switch step {
        case 0: welcomeStep
        case 1: permissionsStep
        case 2: aiCapabilityStep
        case 3: scanScopeStep
        default: quickScanStep
        }
    }

    // MARK: Step 0 — Welcome

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: ODSpacing.lg) {
            HStack(spacing: ODSpacing.md) {
                Image(systemName: "externaldrive.fill")
                    .odIcon(.hero)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ODColors.accent, ODColors.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(y: animateIcon ? -4 : 4)
                    .animation(
                        Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                        value: animateIcon
                    )
                    .onAppear { animateIcon = true }

                VStack(alignment: .leading, spacing: ODSpacing.xs) {
                    Text("OpenDisk")
                        .odTextStyle(.display)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ODColors.accent, ODColors.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Precision disk intelligence for your Mac")
                        .odTextStyle(.body)
                        .foregroundStyle(ODColors.textSecondary)
                        .opacity(taglineVisible ? 1 : 0)
                        .offset(y: taglineVisible ? 0 : 8)
                        .animation(ODAnimation.smooth.delay(0.3), value: taglineVisible)
                        .onAppear { taglineVisible = true }
                }
            }

            Divider().opacity(0.3)

            VStack(alignment: .leading, spacing: ODSpacing.sm) {
                featureRow(icon: "lock.shield.fill", color: ODColors.safe, text: "All analysis stays on-device. No file content leaves your Mac.")
                featureRow(icon: "sparkles", color: .purple, text: "AI-powered cleanup with Apple Intelligence.")
                featureRow(icon: "trash.slash.fill", color: ODColors.review, text: "Always moves to Trash — never permanently deletes.")
            }
        }
    }

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: ODSpacing.md) {
            Image(systemName: icon)
                .odIcon(.body)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .odTextStyle(.body)
                .foregroundStyle(ODColors.textSecondary)
        }
    }

    // MARK: Step 1 — Permissions

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: ODSpacing.md) {
            HStack(spacing: ODSpacing.md) {
                permissionIcon
                VStack(alignment: .leading, spacing: ODSpacing.xs) {
                    Text("Full Disk Access")
                        .odTextStyle(.title)
                    Text("Required for accurate uninstall and orphan detection.")
                        .odTextStyle(.body, color: .textSecondary)
                }
            }

            // Status badge
            HStack(spacing: ODSpacing.sm) {
                Circle()
                    .fill(permissionStatusColor)
                    .frame(width: 10, height: 10)
                Text("Status: \(viewModel.state.permissionStatus.rawValue.capitalized)")
                    .odTextStyle(.heading)
                    .foregroundStyle(permissionStatusColor)
            }
            .padding(ODSpacing.sm)
            .background(permissionStatusColor.opacity(0.1), in: Capsule())
            .animation(ODAnimation.smooth, value: viewModel.state.permissionStatus)

            HStack {
                Button {
                    viewModel.openSystemSettings()
                } label: {
                    HStack(spacing: ODSpacing.xs) {
                        Image(systemName: "gear")
                        Text("Open System Settings")
                    }
                }
                .buttonStyle(ActionButtonStyle(variant: .secondary))
                .accessibilityIdentifier("permissions_open_settings_button")

                Button {
                    Task { await viewModel.refreshPermissionStatus() }
                } label: {
                    HStack(spacing: ODSpacing.xs) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Status")
                    }
                }
                .buttonStyle(ActionButtonStyle(variant: .primary))
            }
        }
    }

    @ViewBuilder
    private var permissionIcon: some View {
        let isDenied = viewModel.state.permissionStatus == .denied
        let isAuthorized = viewModel.state.permissionStatus == .authorized

        ZStack {
            Circle()
                .fill(permissionStatusColor.opacity(0.15))
                .frame(width: 56, height: 56)
                .scaleEffect(isDenied ? 1.08 : 1.0)
                .animation(isDenied ? ODAnimation.breathe : .default, value: isDenied)

            Image(systemName: isAuthorized ? "checkmark.shield.fill" : "shield.lefthalf.filled")
                .odIcon(.large)
                .foregroundStyle(permissionStatusColor)
                .scaleEffect(isAuthorized ? 1.0 : 0.9)
                .rotationEffect(isAuthorized ? .degrees(0) : .degrees(-5))
                .animation(ODAnimation.bouncy, value: viewModel.state.permissionStatus)
        }
    }

    private var permissionStatusColor: Color {
        switch viewModel.state.permissionStatus {
        case .authorized: return ODColors.safe
        case .denied: return ODColors.risky
        case .notDetermined: return ODColors.review
        }
    }

    // MARK: Step 2 — AI Capability

    private var aiCapabilityStep: some View {
        VStack(alignment: .leading, spacing: ODSpacing.md) {
            HStack(spacing: ODSpacing.md) {
                ZStack {
                    Circle()
                        .fill(aiStatusColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: aiStatusIcon)
                        .odIcon(.large)
                        .foregroundStyle(aiStatusColor)
                        .shadow(color: aiStatusColor.opacity(0.4), radius: 8)
                }

                VStack(alignment: .leading, spacing: ODSpacing.xs) {
                    Text("Apple Intelligence")
                        .odTextStyle(.title)
                }
            }

            switch viewModel.state.aiStatus {
            case .supported:
                HStack(spacing: ODSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ODColors.safe)
                    Text("Foundation Model support detected.")
                        .odTextStyle(.body)
                }
                .padding(ODSpacing.sm)
                .background(ODColors.safe.opacity(0.1), in: RoundedRectangle(cornerRadius: ODRadius.sm, style: .continuous))

            case .unsupported(let reason):
                HStack(spacing: ODSpacing.sm) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(ODColors.risky)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reason)
                            .odTextStyle(.body)
                        Text("This build requires Apple Intelligence support.")
                            .odTextStyle(.caption, color: .textSecondary)
                    }
                }
                .padding(ODSpacing.sm)
                .background(ODColors.risky.opacity(0.08), in: RoundedRectangle(cornerRadius: ODRadius.sm, style: .continuous))
            }

            Button {
                viewModel.refreshAICapability()
            } label: {
                HStack(spacing: ODSpacing.xs) {
                    Image(systemName: "arrow.clockwise")
                    Text("Recheck Availability")
                }
            }
            .buttonStyle(ActionButtonStyle(variant: .secondary))
        }
    }

    private var aiStatusColor: Color {
        switch viewModel.state.aiStatus {
        case .supported: return ODColors.safe
        case .unsupported: return ODColors.risky
        }
    }

    private var aiStatusIcon: String {
        switch viewModel.state.aiStatus {
        case .supported: return "brain.head.profile.fill"
        case .unsupported: return "brain.head.profile.fill"
        }
    }

    // MARK: Step 3 — Scan Scope

    private var scanScopeStep: some View {
        VStack(alignment: .leading, spacing: ODSpacing.md) {
            Text("Choose Initial Scan Scope")
                .odTextStyle(.title)

            ForEach(ScanScope.allCases) { scope in
                Button {
                    withAnimation(ODAnimation.snappy) {
                        viewModel.setScope(scope)
                    }
                } label: {
                    scopeCard(scope)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func scopeCard(_ scope: ScanScope) -> some View {
        let isSelected = viewModel.state.selectedScope == scope

        return HStack(spacing: ODSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: ODRadius.sm, style: .continuous)
                    .fill(scopeIconTint(scope).opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: scopeIcon(scope))
                    .odIcon(.regular)
                    .foregroundStyle(scopeIconTint(scope))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(scope.title)
                    .odTextStyle(.heading)
                Text(scope.description)
                    .odTextStyle(.body, color: .textSecondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .odIcon(.checkmark)
                    .foregroundStyle(ODColors.accent)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(ODSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: ODRadius.md, style: .continuous)
                .fill(isSelected ? ODColors.insetSurfaceSelected : ODColors.insetSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ODRadius.md, style: .continuous)
                .stroke(isSelected ? ODColors.accent.opacity(0.4) : ODColors.glassBorderSubtle, lineWidth: isSelected ? 1.5 : 0.5)
        )
        .shadow(color: isSelected ? ODColors.accent.opacity(0.1) : .clear, radius: 8, y: 4)
    }

    private func scopeIcon(_ scope: ScanScope) -> String {
        switch scope {
        case .home: return "house.fill"
        case .applications: return "square.grid.2x2.fill"
        case .fullDisk: return "internaldrive.fill"
        }
    }

    private func scopeIconTint(_ scope: ScanScope) -> Color {
        switch scope {
        case .home: return ODColors.accent
        case .applications: return .purple
        case .fullDisk: return .orange
        }
    }

    // MARK: Step 4 — Quick Scan

    private var quickScanStep: some View {
        VStack(alignment: .leading, spacing: ODSpacing.lg) {
            HStack(spacing: ODSpacing.md) {
                Text("Run First Quick Scan")
                    .odTextStyle(.title)
                Spacer()
            }

            Text("Scan installed apps and prepare uninstall intelligence.")
                .odTextStyle(.body, color: .textSecondary)

            if viewModel.state.isRunningQuickScan {
                VStack(spacing: ODSpacing.md) {
                    ProgressRing(
                        progress: viewModel.state.quickScanProgress,
                        lineWidth: 5,
                        size: 70
                    )

                    Text(viewModel.state.quickScanMessage.isEmpty ? "Scanning..." : viewModel.state.quickScanMessage)
                        .odTextStyle(.caption, color: .textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ODSpacing.lg)
            } else if !viewModel.state.quickScanSummary.isEmpty {
                HStack(spacing: ODSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ODColors.safe)
                    Text(viewModel.state.quickScanSummary)
                        .odTextStyle(.body)
                }
                .padding(ODSpacing.md)
                .background(ODColors.safe.opacity(0.08), in: RoundedRectangle(cornerRadius: ODRadius.sm, style: .continuous))
                .transition(.opacity.combined(with: .offset(y: 8)))
            } else {
                Button {
                    Task { await viewModel.runQuickScan() }
                } label: {
                    HStack(spacing: ODSpacing.xs) {
                        Image(systemName: "magnifyingglass")
                        Text("Start Quick Scan")
                    }
                }
                .buttonStyle(ActionButtonStyle(variant: .primary))
                .accessibilityIdentifier("quickscan_start_button")
            }
        }
    }
}
