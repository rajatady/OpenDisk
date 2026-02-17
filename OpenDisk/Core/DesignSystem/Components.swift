import AppKit
import SwiftUI

// MARK: - Native Glass Surface (AppKit bridge)

struct NativeGlassSurface: NSViewRepresentable {
    let cornerRadius: CGFloat
    let tint: Color
    let material: ODMaterial

    init(cornerRadius: CGFloat, tint: Color = ODColors.accent.opacity(0.06), material: ODMaterial = .regularGlass) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.material = material
    }

    func makeNSView(context: Context) -> NSView {
        if #available(macOS 26.0, *) {
            let view = NSGlassEffectView()
            view.style = .regular
            view.cornerRadius = cornerRadius
            view.wantsLayer = true
            view.layer?.masksToBounds = true
            return view
        } else {
            let view = NSVisualEffectView()
            view.blendingMode = .behindWindow
            switch material {
            case .thinGlass: view.material = .headerView
            case .thickGlass: view.material = .fullScreenUI
            case .sidebarGlass: view.material = .sidebar
            default: view.material = .hudWindow
            }
            view.state = .active
            view.wantsLayer = true
            view.layer?.cornerRadius = cornerRadius
            view.layer?.masksToBounds = true
            return view
        }
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        let nsTint = NSColor(tint)
        if #available(macOS 26.0, *), let glass = nsView as? NSGlassEffectView {
            glass.cornerRadius = cornerRadius
            glass.tintColor = nsTint
        } else if let visual = nsView as? NSVisualEffectView {
            visual.layer?.cornerRadius = cornerRadius
        }
    }
}

// MARK: - GlassPanel (Multi-tier)

struct GlassPanel<Content: View>: View {
    enum Style {
        case card
        case elevated
        case inset
        case hero
    }

    let style: Style
    let content: Content

    init(style: Style = .card, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(glassBackground)
            .overlay(highlightOverlay)
            .overlay(borderOverlay)
            .shadow(color: shadowPreset.color, radius: shadowPreset.radius, x: shadowPreset.x, y: shadowPreset.y)
    }

    private var padding: CGFloat {
        switch style {
        case .inset: return ODSpacing.md
        case .card: return ODSpacing.lg
        case .elevated, .hero: return ODSpacing.xl
        }
    }

    private var glassBackground: some View {
        NativeGlassSurface(cornerRadius: cornerRadius, tint: tintColor, material: glassMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // Inner highlight line at top edge for light refraction
    private var highlightOverlay: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [ODColors.glassHighlight, .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 1)
            .clipShape(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            Spacer()
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(borderColor, lineWidth: borderWidth)
    }

    private var cornerRadius: CGFloat {
        switch style {
        case .inset: return ODRadius.md
        case .card: return ODRadius.lg
        case .elevated: return ODRadius.xl
        case .hero: return ODRadius.xl
        }
    }

    private var glassMaterial: ODMaterial {
        switch style {
        case .inset: return .thinGlass
        case .card: return .regularGlass
        case .elevated: return .thickGlass
        case .hero: return .thickGlass
        }
    }

    private var tintColor: Color {
        switch style {
        case .hero: return ODColors.accent.opacity(0.10)
        default: return glassMaterial.tint
        }
    }

    private var borderColor: Color {
        switch style {
        case .inset: return ODColors.glassBorderSubtle
        default: return ODColors.glassBorder
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .inset: return 0.5
        default: return 1
        }
    }

    private var shadowPreset: ODShadow.Preset {
        switch style {
        case .inset: return ODShadow.subtle
        case .card: return ODShadow.card
        case .elevated: return ODShadow.elevated
        case .hero: return ODShadow.elevated
        }
    }
}

// MARK: - HoverCard

struct HoverCard<Content: View>: View {
    let content: Content
    @State private var isHovered = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .scaleEffect(isHovered ? 1.015 : 1.0)
            .shadow(
                color: isHovered ? ODColors.shadow.opacity(0.5) : ODColors.shadow.opacity(0),
                radius: isHovered ? 20 : 0,
                y: isHovered ? 8 : 0
            )
            .animation(ODAnimation.snappy, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Animated List Row

struct AnimatedListRow<Content: View>: View {
    let index: Int
    let animateEntry: Bool
    let enableHover: Bool
    let content: Content
    @State private var appeared = false
    @State private var isHovered = false

    init(
        index: Int,
        animateEntry: Bool = true,
        enableHover: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.index = index
        self.animateEntry = animateEntry
        self.enableHover = enableHover
        self.content = content()
    }

    var body: some View {
        content
            .background(enableHover && isHovered ? ODColors.hoverOverlay : .clear)
            .offset(x: enableHover && isHovered ? 2 : 0)
            .opacity(animateEntry ? (appeared ? 1 : 0) : 1)
            .offset(y: animateEntry ? (appeared ? 0 : 12) : 0)
            .animation(animateEntry ? ODAnimation.staggerDelay(index: index) : .none, value: appeared)
            .animation(enableHover ? ODAnimation.microInteraction : .none, value: isHovered)
            .onHover { hovering in
                guard enableHover else { return }
                isHovered = hovering
            }
            .onAppear {
                appeared = true
            }
    }
}

// MARK: - Shimmer Loader

struct ShimmerLoader: View {
    let rows: Int
    @State private var phase: CGFloat = -1

    init(rows: Int = 3) {
        self.rows = rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ODSpacing.md) {
            ForEach(0..<rows, id: \.self) { index in
                RoundedRectangle(cornerRadius: ODRadius.sm, style: .continuous)
                    .fill(shimmerGradient)
                    .frame(height: 16)
                    .frame(maxWidth: index == rows - 1 ? 160 : .infinity)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                ODColors.insetSurface.opacity(0.3),
                ODColors.insetSurface.opacity(0.6),
                ODColors.insetSurface.opacity(0.3),
            ],
            startPoint: UnitPoint(x: phase - 0.5, y: 0.5),
            endPoint: UnitPoint(x: phase + 0.5, y: 0.5)
        )
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double?
    var lineWidth: CGFloat = 6
    var size: CGFloat = 60

    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(ODColors.insetSurface, lineWidth: lineWidth)

            if let progress {
                // Determinate
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        AngularGradient(
                            colors: [ODColors.accent, ODColors.accentSecondary, ODColors.accent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(ODAnimation.smooth, value: progress)
            } else {
                // Indeterminate
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        AngularGradient(
                            colors: [ODColors.accent.opacity(0), ODColors.accent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                        withAnimation(ODAnimation.breathe) {
                            pulseScale = 1.06
                        }
                    }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Animated Number

struct AnimatedNumber: View {
    let value: String
    let font: Font
    let color: Color

    init(_ value: String, font: Font = ODTypography.title, color: Color = ODColors.textPrimary) {
        self.value = value
        self.font = font
        self.color = color
    }

    var body: some View {
        Text(value)
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .animation(ODAnimation.smooth, value: value)
    }
}

// MARK: - StatCard (Redesigned)

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    var icon: String? = nil
    var iconColor: Color = ODColors.accent
    var tintColor: Color? = nil

    @State private var isHovered = false

    var body: some View {
        GlassPanel(style: .card) {
            HStack(spacing: ODSpacing.md) {
                if let icon {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 38, height: 38)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }
                }

                VStack(alignment: .leading, spacing: ODSpacing.xs) {
                    Text(title)
                        .font(ODTypography.caption)
                        .foregroundStyle(ODColors.textSecondary)
                    AnimatedNumber(value)
                    Text(subtitle)
                        .font(ODTypography.body)
                        .foregroundStyle(ODColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(ODAnimation.snappy, value: isHovered)
        .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - SizeBadge (Redesigned)

struct SizeBadge: View {
    let bytes: Int64
    var level: SafetyLevel? = nil

    var body: some View {
        Text(Formatting.bytes(bytes))
            .font(ODTypography.caption)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, ODSpacing.sm)
            .padding(.vertical, 3)
            .background(backgroundGradient, in: Capsule())
            .overlay(
                Capsule().stroke(ODColors.glassBorderSubtle, lineWidth: 0.5)
            )
            .contentTransition(.numericText())
            .animation(ODAnimation.smooth, value: bytes)
    }

    private var foregroundColor: Color {
        guard let level else { return ODColors.textPrimary }
        switch level {
        case .safe: return ODColors.safe
        case .review: return ODColors.review
        case .risky: return ODColors.risky
        }
    }

    private var backgroundGradient: some ShapeStyle {
        if let level {
            switch level {
            case .safe:
                return AnyShapeStyle(ODColors.safe.opacity(0.12))
            case .review:
                return AnyShapeStyle(ODColors.review.opacity(0.12))
            case .risky:
                return AnyShapeStyle(ODColors.risky.opacity(0.12))
            }
        }
        return AnyShapeStyle(ODColors.insetSurface)
    }
}

// MARK: - SafetyLabel (Redesigned)

struct SafetyLabel: View {
    let level: SafetyLevel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 9, weight: .bold))
            Text(level.rawValue.capitalized)
                .font(ODTypography.caption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, ODSpacing.sm)
        .padding(.vertical, 3)
        .background(color, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: color.opacity(0.3), radius: 6, y: 2)
    }

    private var iconName: String {
        switch level {
        case .safe: return "checkmark.shield.fill"
        case .review: return "exclamationmark.triangle.fill"
        case .risky: return "xmark.shield.fill"
        }
    }

    private var color: Color {
        switch level {
        case .safe: return ODColors.safe
        case .review: return ODColors.review
        case .risky: return ODColors.risky
        }
    }
}

// MARK: - ActionButtonStyle (Redesigned)

struct ActionButtonStyle: ButtonStyle {
    enum Variant {
        case primary
        case secondary
        case destructive
    }

    let variant: Variant
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ODTypography.heading)
            .padding(.horizontal, ODSpacing.md)
            .padding(.vertical, ODSpacing.sm)
            .foregroundStyle(foreground)
            .background(
                ZStack {
                    Rectangle()
                        .fill(background)
                        .opacity(configuration.isPressed ? 0.82 : 1.0)
                    // Top-edge inner highlight
                    VStack {
                        LinearGradient(
                            colors: [.white.opacity(highlightBrightness), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 1)
                        Spacer()
                    }
                }
                .clipShape(Capsule())
            )
            .overlay(
                Capsule()
                    .stroke(ODColors.glassBorder.opacity(configuration.isPressed ? 0.2 : 0.45), lineWidth: 0.8)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : (isHovered ? 1.03 : 1.0))
            .shadow(
                color: glowColor.opacity(isHovered ? 0.35 : 0),
                radius: isHovered ? 12 : 0,
                y: isHovered ? 4 : 0
            )
            .animation(ODAnimation.snappy, value: configuration.isPressed)
            .animation(ODAnimation.snappy, value: isHovered)
            .onHover { hovering in isHovered = hovering }
    }

    private var highlightBrightness: Double {
        switch variant {
        case .primary: return 0.25
        case .secondary: return 0.40
        case .destructive: return 0.20
        }
    }

    private var background: AnyShapeStyle {
        switch variant {
        case .primary:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [ODColors.accent, ODColors.accentSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .secondary:
            return AnyShapeStyle(ODColors.insetSurface)
        case .destructive:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [ODColors.risky, ODColors.risky.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var foreground: Color {
        switch variant {
        case .secondary: return ODColors.textPrimary
        case .primary, .destructive: return Color.white
        }
    }

    private var glowColor: Color {
        switch variant {
        case .primary: return ODColors.accent
        case .secondary: return .clear
        case .destructive: return ODColors.risky
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: ODSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ODColors.accent)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(ODTypography.heading)
                        .foregroundStyle(ODColors.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(ODTypography.caption)
                            .foregroundStyle(ODColors.textSecondary)
                    }
                }

                Spacer()

                if let trailing {
                    trailing
                }
            }

            Divider()
                .opacity(0.4)
                .padding(.top, ODSpacing.sm)
        }
    }
}

// MARK: - Empty State

struct EmptyState: View {
    let icon: String
    let message: String
    var detail: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @State private var iconBounce = false

    var body: some View {
        VStack(spacing: ODSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(ODColors.textSecondary.opacity(0.5))
                .offset(y: iconBounce ? -4 : 4)
                .animation(
                    Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: iconBounce
                )

            VStack(spacing: ODSpacing.xs) {
                Text(message)
                    .font(ODTypography.heading)
                    .foregroundStyle(ODColors.textSecondary)
                if let detail {
                    Text(detail)
                        .font(ODTypography.body)
                        .foregroundStyle(ODColors.textSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(ActionButtonStyle(variant: .primary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { iconBounce = true }
    }
}

// MARK: - Gradient Canvas

struct GradientCanvas: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    LinearGradient(
                        colors: [ODColors.canvasTop, ODColors.canvasBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    RadialGradient(
                        colors: [ODColors.canvasGlow, .clear],
                        center: .topTrailing,
                        startRadius: 20,
                        endRadius: 480
                    )

                    RadialGradient(
                        colors: [ODColors.canvasAmberGlow, .clear],
                        center: .bottomLeading,
                        startRadius: 10,
                        endRadius: 460
                    )

                    RadialGradient(
                        colors: [ODColors.canvasMintGlow, .clear],
                        center: UnitPoint(x: 0.3, y: 0.7),
                        startRadius: 30,
                        endRadius: 350
                    )
                }
                .ignoresSafeArea()
            )
    }
}

extension View {
    func odCanvasBackground() -> some View {
        modifier(GradientCanvas())
    }
}
