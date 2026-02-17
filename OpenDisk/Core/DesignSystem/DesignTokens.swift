import AppKit
import SwiftUI

// MARK: - Dynamic Color Helper

extension Color {
    static func odDynamic(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [.darkAqua, .aqua])
            return match == .darkAqua ? dark : light
        })
    }
}

// MARK: - Color Tokens

enum ODColors {
    // Canvas
    static let canvasTop = Color.odDynamic(
        light: NSColor(srgbRed: 0.96, green: 0.97, blue: 0.99, alpha: 1),
        dark: NSColor(srgbRed: 0.06, green: 0.07, blue: 0.10, alpha: 1)
    )
    static let canvasBottom = Color.odDynamic(
        light: NSColor(srgbRed: 0.90, green: 0.93, blue: 0.98, alpha: 1),
        dark: NSColor(srgbRed: 0.10, green: 0.11, blue: 0.16, alpha: 1)
    )
    static let canvasGlow = Color.odDynamic(
        light: NSColor(srgbRed: 0.22, green: 0.62, blue: 0.96, alpha: 0.28),
        dark: NSColor(srgbRed: 0.31, green: 0.76, blue: 0.98, alpha: 0.20)
    )
    static let canvasAmberGlow = Color.odDynamic(
        light: NSColor(srgbRed: 0.96, green: 0.72, blue: 0.47, alpha: 0.15),
        dark: NSColor(srgbRed: 0.98, green: 0.72, blue: 0.45, alpha: 0.10)
    )
    static let canvasMintGlow = Color.odDynamic(
        light: NSColor(srgbRed: 0.30, green: 0.85, blue: 0.70, alpha: 0.12),
        dark: NSColor(srgbRed: 0.25, green: 0.80, blue: 0.65, alpha: 0.08)
    )

    // Glass surfaces
    static let glass = Color.odDynamic(
        light: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.55),
        dark: NSColor(srgbRed: 0.17, green: 0.18, blue: 0.23, alpha: 0.58)
    )
    static let glassStrong = Color.odDynamic(
        light: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.75),
        dark: NSColor(srgbRed: 0.20, green: 0.21, blue: 0.27, alpha: 0.78)
    )
    static let glassThin = Color.odDynamic(
        light: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.35),
        dark: NSColor(srgbRed: 0.15, green: 0.16, blue: 0.20, alpha: 0.40)
    )
    static let glassBorder = Color.odDynamic(
        light: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.55),
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.18)
    )
    static let glassBorderSubtle = Color.odDynamic(
        light: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.30),
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.10)
    )
    static let glassHighlight = Color.odDynamic(
        light: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.80),
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.12)
    )
    static let insetSurface = Color.odDynamic(
        light: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.50),
        dark: NSColor(srgbRed: 0.23, green: 0.24, blue: 0.30, alpha: 0.62)
    )
    static let insetSurfaceSelected = Color.odDynamic(
        light: NSColor(srgbRed: 0.92, green: 0.96, blue: 1, alpha: 0.80),
        dark: NSColor(srgbRed: 0.21, green: 0.30, blue: 0.40, alpha: 0.76)
    )

    // Semantic
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let accent = Color(red: 0.08, green: 0.49, blue: 0.94)
    static let accentSecondary = Color(red: 0.01, green: 0.72, blue: 0.88)
    static let safe = Color(red: 0.10, green: 0.67, blue: 0.37)
    static let review = Color(red: 0.90, green: 0.58, blue: 0.15)
    static let risky = Color(red: 0.83, green: 0.25, blue: 0.24)

    // Shadows
    static let shadow = Color.odDynamic(
        light: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.08),
        dark: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.45)
    )
    static let shadowDeep = Color.odDynamic(
        light: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.14),
        dark: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.60)
    )
    static let shadowSubtle = Color.odDynamic(
        light: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.04),
        dark: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.25)
    )

    // Hover
    static let hoverOverlay = Color.odDynamic(
        light: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.03),
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.04)
    )
}

// MARK: - Spacing

enum ODSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let xxl: CGFloat = 36
}

// MARK: - Radii

enum ODRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
}

// MARK: - Typography

enum ODTypography {
    static let display = Font.system(size: 38, weight: .bold, design: .rounded)
    static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let heading = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 13, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 11, weight: .medium, design: .rounded)
    static let mono = Font.system(size: 11, weight: .regular, design: .monospaced)

    // Icon fonts
    static let iconHero = Font.system(size: 44, weight: .light)
    static let iconLarge = Font.system(size: 24, weight: .medium)
    static let iconMedium = Font.system(size: 18, weight: .medium)
    static let iconDefault = Font.system(size: 16, weight: .semibold)
    static let iconBody = Font.system(size: 14, weight: .medium)
    static let iconSmall = Font.system(size: 12, weight: .semibold)
    static let iconCaption = Font.system(size: 10, weight: .medium)
    static let iconMicro = Font.system(size: 9, weight: .bold)
    static let iconTiny = Font.system(size: 9, weight: .medium)
    static let iconCheckmark = Font.system(size: 20)
}

// MARK: - Animation Tokens

enum ODAnimation {
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let microInteraction = Animation.spring(response: 0.15, dampingFraction: 0.8)
    static let pageTransition = Animation.spring(response: 0.45, dampingFraction: 0.82)
    static let breathe = Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)

    static func staggerDelay(index: Int) -> Animation {
        Animation.spring(response: 0.4, dampingFraction: 0.78).delay(Double(index) * 0.05)
    }
}

// MARK: - Shadow Presets

enum ODShadow {
    struct Preset {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    static let subtle = Preset(color: ODColors.shadowSubtle, radius: 4, x: 0, y: 2)
    static let card = Preset(color: ODColors.shadow, radius: 16, x: 0, y: 8)
    static let elevated = Preset(color: ODColors.shadowDeep, radius: 28, x: 0, y: 16)

    static func glow(_ color: Color) -> Preset {
        Preset(color: color.opacity(0.35), radius: 20, x: 0, y: 4)
    }
}

extension View {
    func odShadow(_ preset: ODShadow.Preset) -> some View {
        self.shadow(color: preset.color, radius: preset.radius, x: preset.x, y: preset.y)
    }
}

// MARK: - Material Tokens

enum ODMaterial {
    case thinGlass
    case regularGlass
    case thickGlass
    case sidebarGlass

    var tint: Color {
        switch self {
        case .thinGlass:
            return ODColors.accent.opacity(0.03)
        case .regularGlass:
            return ODColors.accent.opacity(0.06)
        case .thickGlass:
            return ODColors.accent.opacity(0.10)
        case .sidebarGlass:
            return ODColors.accent.opacity(0.04)
        }
    }

    var blurRadius: CGFloat {
        switch self {
        case .thinGlass: return 20
        case .regularGlass: return 30
        case .thickGlass: return 50
        case .sidebarGlass: return 25
        }
    }

    var fillColor: Color {
        switch self {
        case .thinGlass: return ODColors.glassThin
        case .regularGlass: return ODColors.glass
        case .thickGlass: return ODColors.glassStrong
        case .sidebarGlass: return ODColors.glassThin
        }
    }
}

// MARK: - Token Enums (for modifiers)

enum ODTextToken {
    case display
    case title
    case heading
    case body
    case caption
    case mono

    var font: Font {
        switch self {
        case .display: return ODTypography.display
        case .title: return ODTypography.title
        case .heading: return ODTypography.heading
        case .body: return ODTypography.body
        case .caption: return ODTypography.caption
        case .mono: return ODTypography.mono
        }
    }
}

enum ODIconToken {
    case hero
    case large
    case medium
    case regular
    case body
    case small
    case caption
    case micro
    case tiny
    case checkmark

    var font: Font {
        switch self {
        case .hero: return ODTypography.iconHero
        case .large: return ODTypography.iconLarge
        case .medium: return ODTypography.iconMedium
        case .regular: return ODTypography.iconDefault
        case .body: return ODTypography.iconBody
        case .small: return ODTypography.iconSmall
        case .caption: return ODTypography.iconCaption
        case .micro: return ODTypography.iconMicro
        case .tiny: return ODTypography.iconTiny
        case .checkmark: return ODTypography.iconCheckmark
        }
    }
}

enum ODColorToken {
    case textPrimary
    case textSecondary
    case accent
    case accentSecondary
    case safe
    case review
    case risky
    case glassBorder
    case insetSurface
    case insetSurfaceSelected

    var color: Color {
        switch self {
        case .textPrimary: return ODColors.textPrimary
        case .textSecondary: return ODColors.textSecondary
        case .accent: return ODColors.accent
        case .accentSecondary: return ODColors.accentSecondary
        case .safe: return ODColors.safe
        case .review: return ODColors.review
        case .risky: return ODColors.risky
        case .glassBorder: return ODColors.glassBorder
        case .insetSurface: return ODColors.insetSurface
        case .insetSurfaceSelected: return ODColors.insetSurfaceSelected
        }
    }
}
